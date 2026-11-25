# BeamMP: the server runs here, bound to localhost, and friends reach it over tailcat.
# Nothing runs at boot: `beammp-host` starts the server and tunnel, prints the address,
# offers to start the client, and stops both again on Ctrl+C, which also discards the
# tunnel key: every session has a new address and the last one is dead.
# - Play here: Direct Connect to 127.0.0.1:30814.
# - Invite: send the session's address, privately (it is the only credential). They run
#   `beamcat connect <address>` (`nix build .#beamcat-windows` for the .exe) and Direct
#   Connect to 127.0.0.1:30814.
# - Mods: add zips to clientMods, or copy them into /var/lib/beammp-server/Resources/Client
#   and `systemctl restart beammp-server`.
{
  config,
  outputs,
  pkgs,
  username,
  ...
}: let
  cfg = config.services.beammp-server;

  beammp-host = pkgs.writeShellApplication {
    name = "beammp-host";
    runtimeInputs = [
      config.systemd.package
      pkgs.coreutils
      pkgs.beammp-launcher
      # The launcher starts the native Linux game, which needs Steam's FHS runtime.
      config.programs.steam.package.run
    ];
    text = ''
      usage() {
        cat <<EOF
      usage: beammp-host [--client | --no-client]

      Start the BeamMP server and its tailcat tunnel, print the address friends connect
      with, then start the BeamMP client (asks, unless --client or --no-client is given).
      Both keep running until Ctrl+C, which stops them and retires the address: the next
      session gets a new one.
      EOF
      }

      client=ask
      case "''${1:-}" in
        "") ;;
        -c | --client) client=yes ;;
        -n | --no-client) client=no ;;
        -h | --help)
          usage
          exit 0
          ;;
        *)
          usage >&2
          exit 2
          ;;
      esac

      # polkit and the address file both go by this process's groups, and a group granted
      # after login reaches only new sessions; sg adds it to this one (no password for a
      # listed member).
      if [[ " $(id -nG) " != *" beammp "* ]]; then
        exec ${config.security.wrapperDir}/sg beammp -c "$(printf '%q ' "$0" "$@")"
      fi

      # Every way out stops both, including a failed start. One unit per call: the
      # polkit rule that lets the beammp group do this checks a single unit.
      stop() {
        trap - EXIT
        # A signal sent to the script alone (not the terminal's Ctrl+C) leaves it behind.
        [[ -z ''${sleeper:-} ]] || kill "$sleeper" 2>/dev/null || true
        echo
        echo "Stopping the BeamMP server..."
        systemctl stop beammp-tailcat.service || true
        systemctl stop beammp-server.service || true
      }
      trap stop EXIT
      trap 'exit 130' INT
      trap 'exit 143' TERM
      trap 'exit 129' HUP

      systemctl start beammp-server.service
      systemctl start beammp-tailcat.service

      # beamcat writes it once it listens on its relay. The file goes when the tunnel
      # stops, so whatever is there belongs to this session.
      address=
      for _ in $(seq 30); do
        if systemctl is-active --quiet beammp-tailcat.service &&
          address=$(cat ${cfg.tailcat.addressFile} 2>/dev/null) &&
          [[ -n $address ]]; then
          break
        fi
        sleep 1
      done
      if [[ -z $address ]]; then
        echo "beammp-host: no tailcat address after 30 s; see journalctl -u beammp-tailcat" >&2
        exit 1
      fi

      cat <<EOF
      BeamMP server "${cfg.name}" is up.

        Here:     Direct Connect to 127.0.0.1:${toString cfg.port}
        Friends:  beamcat connect <address>, then Direct Connect to 127.0.0.1:${toString cfg.port}

      Address for this session (send it privately; anyone who has it can join):
      $address
      EOF

      if [[ $client == ask ]]; then
        client=no
        if [[ -t 0 ]]; then
          read -rp $'\nStart the BeamMP client? [y/N] ' answer || answer=
          [[ $answer == [yY]* ]] && client=yes
        fi
      fi

      if [[ $client == yes ]]; then
        # The launcher keeps Launcher.cfg, its key, log and mod cache in its working
        # directory. It exits non-zero when the game closes; the server stays up.
        dir=''${XDG_DATA_HOME:-$HOME/.local/share}/BeamMP-Launcher
        mkdir -p "$dir"
        (cd "$dir" && steam-run BeamMP-Launcher) || true
        echo
        echo "The client closed; the server is still running."
      fi

      echo "Press Ctrl+C to stop the server."
      # In the background, so Ctrl+C runs the trap at once instead of after sleep.
      sleep infinity &
      sleeper=$!
      wait "$sleeper"
    '';
  };
in {
  imports = [outputs.nixosModules.beammp-server];

  age.secrets.beammp-auth-key.file = ../../secrets/beammp_auth_key.age;

  services.beammp-server = {
    enable = true;
    authKeyFile = config.age.secrets.beammp-auth-key.path;
    # beammp-host starts and stops it.
    autoStart = false;
    name = "nix server";
    # From the roane_county mod below.
    map = "SouthernHighway";
    maxCars = 10;
    clientMods = {
      # UI app showing power, weight and power-to-weight ratio, v2.2.
      # https://www.beamng.com/resources/simple-power-weight-ratio.23693/
      simple_power_weight_ratio = pkgs.fetchurl {
        name = "simple_power_weight_ratio.zip";
        url = "https://www.beamng.com/resources/simple-power-weight-ratio.23693/download?version=69578";
        hash = "sha256-lIWbai1TZZ54tHXXdptYSi+E/vXsw+8ThcIWbgLaz94=";
      };
      # 2020 Hirochi CCF, Rework 1.2.5.2.
      # https://www.beamng.com/resources/2020-hirochi-ccf.29318/
      hirochi_ccf = pkgs.fetchurl {
        name = "hirochi_ccf.zip";
        url = "https://www.beamng.com/resources/2020-hirochi-ccf.29318/download?version=74976";
        hash = "sha256-4l85Io7xf/sIDjHiPU+qJjeft+KsjzQrDJmM9vhaxBA=";
      };
      # Roane County TN USA, for BeamNG 0.19: 175 sq mi of East Tennessee around Kingston,
      # Rockwood and Harriman. Its level folder is SouthernHighway.
      # https://www.beamng.com/resources/roane-county-tennessee-usa.1586/
      roane_county = pkgs.fetchurl {
        name = "roane_county.zip";
        url = "https://www.beamng.com/resources/roane-county-tennessee-usa.1586/download?version=22922";
        hash = "sha256-ro2JqEbzK2AS8ur+YraearyVDKFJode8b/seIupA0+c=";
      };
      # Volvo V90 by BYLO Productions, from modsfire. Its download links expire after ten
      # minutes, so it can't be fetched: get the zip again and
      # `nix-store --add-fixed sha256 v902BYLOPRODUCTIONS.zip`.
      volvo_v90 = pkgs.requireFile {
        name = "v902BYLOPRODUCTIONS.zip";
        url = "https://modsfire.com/";
        hash = "sha256-JcbMkfWtd9dCLzaHpDgmXoRZTMGnR8jPXu0aCIy05aw=";
      };
    };
    tailcat = {
      enable = true;
      # A new address every beammp-host session; Ctrl+C retires the old one.
      stableAddress = false;
    };
  };

  # Drop mods into Resources/ and read the tailcat address without sudo.
  users.users.${username}.extraGroups = ["beammp"];

  # The launcher starts BeamNG's native Linux build itself, inside steam-run rather than
  # Steam's own runtime container, and its embedded Chromium links these, which Steam's
  # FHS env lacks.
  programs.steam.extraPackages = with pkgs; [nspr nss at-spi2-core libxcomposite];

  environment.systemPackages = [beammp-host];
}
