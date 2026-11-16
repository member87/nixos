# A BeamMP server for BeamNG.drive, configured entirely through BeamMP-Server's BEAMMP_*
# environment variables (no ServerConfig.toml), with mods and plugins from Nix or dropped
# into the data directory by hand, and optionally reachable over tailcat (pkgs/beamcat).
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.beammp-server;

  inherit (lib) concatLines escapeShellArg getExe mapAttrsToList mkEnableOption mkIf mkOption mkPackageOption types;

  dataDir = "/var/lib/beammp-server";
  resources = "${dataDir}/Resources";

  # Where beamcat reaches the server: loopback when it listens on every address.
  targetHost =
    {
      "::" = "127.0.0.1";
      "::ffff:127.0.0.1" = "127.0.0.1";
    }
    .${
      cfg.listenAddress
    }
    or "[${cfg.listenAddress}]";

  boolStr = b:
    if b
    then "true"
    else "false";

  # Names become file names under Resources/; nothing that escapes the directory.
  safeName = name: builtins.match "[A-Za-z0-9][A-Za-z0-9._ -]*" name != null;

  hardening = {
    NoNewPrivileges = true;
    PrivateTmp = true;
    PrivateDevices = true;
    ProtectHome = true;
    ProtectSystem = "strict";
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectKernelLogs = true;
    ProtectControlGroups = true;
    ProtectClock = true;
    ProtectHostname = true;
    RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX" "AF_NETLINK"];
    RestrictNamespaces = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    LockPersonality = true;
    SystemCallArchitectures = "native";
  };
in {
  options.services.beammp-server = {
    enable = mkEnableOption "the BeamMP server";

    package = mkPackageOption pkgs "beammp-server" {};

    autoStart = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Start the server, and beamcat with it, at boot. Off, they run only when started
        with systemctl, which members of the beammp group may do without sudo.
      '';
    };

    authKeyFile = mkOption {
      type = types.path;
      description = ''
        File holding the AuthKey from https://keymaster.beammp.com/. BeamMP-Server refuses
        to start without one, even when private. Read through a systemd credential, so it
        can be root-only.
      '';
    };

    name = mkOption {
      type = types.str;
      default = "BeamMP Server";
      description = "Server name shown to players.";
    };

    description = mkOption {
      type = types.str;
      default = "BeamMP on NixOS";
      description = "Server description shown to players.";
    };

    tags = mkOption {
      type = types.str;
      default = "Freeroam";
      description = "Comma-separated tags for the server list.";
    };

    map = mkOption {
      type = types.str;
      default = "gridmap_v2";
      example = "west_coast_usa";
      description = ''
        Level to load: the folder name under /levels/, for a stock map or one from a map
        mod in {option}`clientMods` (the folder inside the mod's zip).
      '';
    };

    maxPlayers = mkOption {
      type = types.ints.positive;
      default = 8;
      description = "Players allowed at once.";
    };

    maxCars = mkOption {
      type = types.ints.positive;
      default = 1;
      description = "Vehicles each player may spawn.";
    };

    private = mkOption {
      type = types.bool;
      default = true;
      description = "Keep the server off the public BeamMP server list.";
    };

    allowGuests = mkOption {
      type = types.bool;
      default = true;
      description = "Let players join without a BeamMP account.";
    };

    listenAddress = mkOption {
      type = types.str;
      default = "::ffff:127.0.0.1";
      description = ''
        IPv6 address the server binds, TCP and UDP. BeamMP-Server treats every peer
        address as IPv6 and drops a player on an IPv4 socket at login ("bad address
        cast"), so 127.0.0.1 is spelled as its IPv4-mapped form: the default still
        accepts only 127.0.0.1, keeping the server off every network. Players on this
        machine connect to 127.0.0.1, everyone else through tailcat; `::` opens it to
        the LAN.
      '';
    };

    port = mkOption {
      type = types.port;
      default = 30814;
      description = "Port for both the TCP session and the UDP vehicle updates.";
    };

    clientMods = mkOption {
      type = types.attrsOf types.path;
      default = {};
      example = lib.literalExpression ''
        {
          some_car = pkgs.fetchurl {
            url = "https://example.com/some_car.zip";
            hash = "sha256-...";
          };
        }
      '';
      description = ''
        BeamNG mod zips players download when they join, linked into Resources/Client as
        `<name>.zip`. Zips copied into ${resources}/Client by hand work too.
      '';
    };

    serverPlugins = mkOption {
      type = types.attrsOf types.path;
      default = {};
      description = ''
        BeamMP Lua plugin directories, linked into Resources/Server as `<name>`. These are
        read-only; a plugin that writes into its own directory has to be copied into
        ${resources}/Server by hand instead.
      '';
    };

    tailcat = {
      enable = mkEnableOption ''
        serving the server over tailcat with beamcat. The address players connect to is
        written to {option}`tailcat.addressFile`, readable by the beammp group. Anyone who
        has it can join, so share it privately
      '';

      package = mkPackageOption pkgs "beamcat" {};

      stableAddress = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Keep the tunnel key, and so the address, across stops. Off, the key lives in a
          runtime directory that survives restarts but is deleted when the service stops,
          so every start hands out a new address and every old one is dead.
        '';
      };

      addressFile = mkOption {
        type = types.str;
        readOnly = true;
        default = "${
          if cfg.tailcat.stableAddress
          then "/var/lib"
          else "/run"
        }/beammp-tailcat/address";
        description = "Where beamcat writes the address while it runs.";
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.all safeName (lib.attrNames cfg.clientMods ++ lib.attrNames cfg.serverPlugins);
        message = "services.beammp-server: clientMods and serverPlugins names must be plain file names.";
      }
      {
        assertion = lib.hasInfix ":" cfg.listenAddress;
        message = "services.beammp-server.listenAddress must be IPv6 (write 127.0.0.1 as ::ffff:127.0.0.1): BeamMP-Server drops players on an IPv4 socket.";
      }
    ];

    users.users.beammp = {
      isSystemUser = true;
      group = "beammp";
      home = dataDir;
    };
    users.groups.beammp = {};

    # Group-writable and setgid, so members of the beammp group can drop in mods and
    # plugins and the server can read them.
    systemd.tmpfiles.settings.beammp-server = let
      dir = mode: {
        d = {
          user = "beammp";
          group = "beammp";
          inherit mode;
        };
      };
    in {
      ${dataDir} = dir "0750";
      ${resources} = dir "2775";
      "${resources}/Client" = dir "2775";
      "${resources}/Server" = dir "2775";
    };

    # Members of the beammp group start, stop and restart both services without sudo.
    # polkit checks the caller's own groups, so a new member logs in again first.
    security.polkit.extraConfig = ''
      polkit.addRule(function (action, subject) {
        if (action.id != "org.freedesktop.systemd1.manage-units" || !subject.isInGroup("beammp")) {
          return polkit.Result.NOT_HANDLED;
        }
        var unit = action.lookup("unit");
        var verb = action.lookup("verb");
        if ((unit == "beammp-server.service" || unit == "beammp-tailcat.service") &&
            (verb == "start" || verb == "stop" || verb == "restart")) {
          return polkit.Result.YES;
        }
        return polkit.Result.NOT_HANDLED;
      });
    '';

    systemd.services.beammp-server = {
      description = "BeamMP server";
      wantedBy = lib.optional cfg.autoStart "multi-user.target";
      # authenticates players and itself with backend.beammp.com
      wants = ["network-online.target"];
      after = ["network-online.target"];

      # Every setting is given: with no config file, an unset one logs a type warning.
      environment = {
        BEAMMP_PROVIDER_DISABLE_CONFIG = "true";
        BEAMMP_NAME = cfg.name;
        BEAMMP_DESCRIPTION = cfg.description;
        BEAMMP_TAGS = cfg.tags;
        BEAMMP_MAP = "/levels/${cfg.map}/info.json";
        BEAMMP_MAX_PLAYERS = toString cfg.maxPlayers;
        BEAMMP_MAX_CARS = toString cfg.maxCars;
        BEAMMP_PRIVATE = boolStr cfg.private;
        BEAMMP_ALLOW_GUESTS = boolStr cfg.allowGuests;
        BEAMMP_IP = cfg.listenAddress;
        BEAMMP_PORT = toString cfg.port;
        BEAMMP_RESOURCE_FOLDER = resources;
        BEAMMP_LOG_CHAT = "true";
        BEAMMP_DEBUG = "false";
        BEAMMP_INFORMATION_PACKET = "true";
        # Nix pins the version; the "new version available" nag can't be acted on here.
        BEAMMP_IM_SCARED_OF_UPDATES = "true";
        BEAMMP_UPDATE_REMINDER_TIME = "30s";
      };

      # Relink the Nix-provided mods and plugins: drop every link into the store, then
      # link the current set. Hand-copied files are left alone, and one with the same
      # name as a Nix entry fails the start instead of being overwritten.
      preStart = ''
        find ${resources}/Client ${resources}/Server -maxdepth 1 -type l -lname '/nix/store/*' -delete
        ${concatLines (mapAttrsToList (name: path: "ln -sT ${path} ${escapeShellArg "${resources}/Client/${name}.zip"}") cfg.clientMods)}
        ${concatLines (mapAttrsToList (name: path: "ln -sT ${path} ${escapeShellArg "${resources}/Server/${name}"}") cfg.serverPlugins)}
      '';

      script = ''
        BEAMMP_AUTH_KEY=$(<"$CREDENTIALS_DIRECTORY/auth-key")
        export BEAMMP_AUTH_KEY
        exec ${getExe cfg.package}
      '';

      serviceConfig =
        hardening
        // {
          User = "beammp";
          Group = "beammp";
          WorkingDirectory = dataDir; # Server.log
          ReadWritePaths = [dataDir];
          LoadCredential = ["auth-key:${cfg.authKeyFile}"];
          Restart = "on-failure";
          RestartSec = 5;
        };
    };

    systemd.services.beammp-tailcat = mkIf cfg.tailcat.enable {
      description = "BeamMP server over tailcat";
      wantedBy = lib.optional cfg.autoStart "multi-user.target";
      wants = ["network-online.target"];
      after = ["network-online.target" "beammp-server.service"];

      serviceConfig =
        hardening
        // {
          User = "beammp";
          Group = "beammp";
          ExecStart = "${getExe cfg.tailcat.package} serve -state ${dirOf cfg.tailcat.addressFile} -target ${targetHost}:${toString cfg.port} -port ${toString cfg.port}";
          Restart = "always";
          RestartSec = 5;
        }
        // (
          if cfg.tailcat.stableAddress
          then {
            StateDirectory = "beammp-tailcat";
            StateDirectoryMode = "0750";
          }
          else {
            RuntimeDirectory = "beammp-tailcat";
            RuntimeDirectoryMode = "0750";
            # Kept across a crash restart, so the address printed for this session holds.
            RuntimeDirectoryPreserve = "restart";
          }
        );
    };
  };
}
