# Sunshine game-stream host for Moonlight clients. Runs as a user service in the
# Hyprland session; pair clients in the web UI at https://localhost:47990. Its settings
# and apps pages are read-only: `settings` and `applications` below make the module start
# Sunshine with both from the store. Pairing and credentials stay in ~/.config/sunshine.
{
  config,
  pkgs,
  ...
}: let
  # Streams go to a headless output sized to the client, so a 16:9 client gets a 16:9
  # desktop instead of the 3440x1440 ultrawide letterboxed. The physical screens are
  # turned off for the stream: their workspaces move to the headless output, and it is
  # then the only wl_output, the one Sunshine captures by default.
  streamDisplay = pkgs.writeShellApplication {
    name = "sunshine-stream-display";
    runtimeInputs = [config.programs.hyprland.package pkgs.jq];
    text = ''
      output=SUNSHINE

      case "''${1:-}" in
        do)
          # Sunshine passes the client's requested mode to prep commands.
          mode="''${SUNSHINE_CLIENT_WIDTH:-1920}x''${SUNSHINE_CLIENT_HEIGHT:-1080}@''${SUNSHINE_CLIENT_FPS:-60}"

          # A stream that ended without its undo (Sunshine crashed) leaves one behind.
          hyprctl -q output remove "$output" || true
          hyprctl -q output create headless "$output"
          hyprctl -q eval "hl.monitor({ output = \"$output\", mode = \"$mode\", position = \"auto\", scale = 1 })"

          # Created first, so there is always a screen for the workspaces to move to.
          hyprctl monitors -j | jq -r --arg keep "$output" '.[].name | select(. != $keep)' |
            while read -r monitor; do
              hyprctl -q eval "hl.monitor({ output = \"$monitor\", disabled = true })"
            done
          ;;
        undo)
          # Also run when the service stops, so a no-op without a stream display, and
          # without Hyprland (logging out stops the service after the compositor).
          hyprctl monitors all -j 2>/dev/null |
            jq -e --arg output "$output" 'any(.[]; .name == $output)' >/dev/null || exit 0

          # Reloading drops the rules set above, so the config's monitor rules turn the
          # physical screens back on; removing the output then moves its workspaces home.
          hyprctl -q reload
          hyprctl -q output remove "$output"
          ;;
        *)
          echo "usage: sunshine-stream-display do|undo" >&2
          exit 2
          ;;
      esac
    '';
  };

  # An app's command, for apps that should end with the stream. Sunshine keeps an app
  # running after its client disconnects, to resume it, and runs the prep commands' undo
  # only once the app quits; without this, closing Moonlight left the screens off. The
  # app quits when this exits, at the first disconnect after launch.
  untilDisconnect = pkgs.writeShellApplication {
    name = "sunshine-until-disconnect";
    runtimeInputs = [config.systemd.package];
    text = ''
      exec {log}< <(journalctl --user --unit sunshine --follow --lines 0 --output cat)
      journal=$!
      while read -r -u "$log" line; do
        [[ $line == *"CLIENT DISCONNECTED"* ]] && break
      done
      kill "$journal" 2>/dev/null || true
    '';
  };

  # Sunshine treats an app that exits 0 within 5 s as a launcher and keeps the session
  # open: a client gone that quickly would leave the screens off.
  streamApp = app:
    app
    // {
      cmd = "${untilDisconnect}/bin/sunshine-until-disconnect";
      auto-detach = "false";
    };
in {
  services.sunshine = {
    enable = true;
    # The module opens these on every interface; lan-firewall.nix scopes them.
    openFirewall = false;
    settings.global_prep_cmd = builtins.toJSON [
      {
        do = "${streamDisplay}/bin/sunshine-stream-display do";
        undo = "${streamDisplay}/bin/sunshine-stream-display undo";
      }
    ];
    applications = {
      env.PATH = "$(PATH):$(HOME)/.local/bin";
      apps = map streamApp [
        {
          name = "Desktop";
          image-path = "desktop.png";
        }
        {
          name = "Steam Big Picture";
          image-path = "steam.png";
          detached = ["setsid steam steam://open/bigpicture"];
          prep-cmd = [
            {
              do = "";
              undo = "setsid steam steam://close/bigpicture";
            }
          ];
        }
      ];
    };
  };

  # If Sunshine crashes mid-stream, no undo runs.
  systemd.user.services.sunshine.serviceConfig.ExecStopPost = "${streamDisplay}/bin/sunshine-stream-display undo";

  # Base port 47989 and its fixed offsets (the module's openFirewall list).
  networking.firewall.lan = {
    allowedTCPPorts = [47984 47989 47990 48010];
    allowedUDPPorts = [47998 47999 48000 48002 48010];
  };
}
