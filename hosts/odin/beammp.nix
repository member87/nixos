# BeamMP: the server runs here, bound to localhost, and friends reach it over tailcat.
# `beammp-host` starts both services if needed, prints the address, then offers to start
# the client.
# - Play here: Direct Connect to 127.0.0.1:30814.
# - Invite: send the address, privately (it is the only credential). They run
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

      # The polkit rule in the beammp-server module lets the beammp group do this.
      for unit in beammp-server.service beammp-tailcat.service; do
        systemctl is-active --quiet "$unit" || systemctl start "$unit"
      done

      # The address file is beammp-group only, and a new group reaches only sessions
      # started after it was granted; sudo covers that gap.
      read_address=(cat)
      [[ " $(id -nG) " == *" beammp "* ]] || read_address=(sudo cat)

      # beamcat writes it once it listens on its relay; the address never changes, so an
      # older copy from before a restart is just as good.
      address=
      for _ in $(seq 30); do
        if systemctl is-active --quiet beammp-tailcat.service &&
          address=$("''${read_address[@]}" /var/lib/beammp-tailcat/address 2>/dev/null) &&
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

      Address (send it privately; anyone who has it can join):
      $address
      EOF

      if [[ $client == ask ]]; then
        client=no
        if [[ -t 0 ]]; then
          read -rp $'\nStart the BeamMP client? [y/N] ' answer || answer=
          [[ $answer == [yY]* ]] && client=yes
        fi
      fi
      [[ $client == yes ]] || exit 0

      # The launcher keeps Launcher.cfg, its key, log and mod cache in its working directory.
      dir=''${XDG_DATA_HOME:-$HOME/.local/share}/BeamMP-Launcher
      mkdir -p "$dir"
      cd "$dir"
      exec steam-run BeamMP-Launcher
    '';
  };
in {
  imports = [outputs.nixosModules.beammp-server];

  age.secrets.beammp-auth-key.file = ../../secrets/beammp_auth_key.age;

  services.beammp-server = {
    enable = true;
    authKeyFile = config.age.secrets.beammp-auth-key.path;
    name = "nix server";
    map = "west_coast_usa";
    tailcat.enable = true;
  };

  # Drop mods into Resources/ and read the tailcat address without sudo.
  users.users.${username}.extraGroups = ["beammp"];

  # The launcher starts BeamNG's native Linux build itself, inside steam-run rather than
  # Steam's own runtime container, and its embedded Chromium links these, which Steam's
  # FHS env lacks.
  programs.steam.extraPackages = with pkgs; [nspr nss at-spi2-core libxcomposite];

  environment.systemPackages = [beammp-host];
}
