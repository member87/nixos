# Sunshine game-stream host for Moonlight clients. Runs as a user service in the
# Hyprland session; pair clients in the web UI at https://localhost:47990, which only
# this machine can reach. Its settings and apps pages are read-only: `settings` and
# `applications` below make the module start Sunshine with both from the store. Pairing
# and credentials stay in ~/.config/sunshine.
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

  # hypridle's timers see keyboards, pointers and touch but not gamepads: a stream played
  # on a controller would lock the session after 5 minutes and suspend it after 30. Held
  # for the stream as the bar's Caffeine toggle holds it, in a unit so that undo and
  # ExecStopPost can release it.
  streamInhibit = pkgs.writeShellApplication {
    name = "sunshine-stream-inhibit";
    runtimeInputs = [config.systemd.package];
    text = ''
      unit=sunshine-inhibit

      case "''${1:-}" in
        do)
          systemctl --user stop "$unit" 2>/dev/null || true
          systemd-run --user --quiet --collect --unit "$unit" \
            systemd-inhibit --what=idle:sleep --who=Sunshine --why="Streaming to Moonlight" --mode=block \
            sleep infinity
          ;;
        undo)
          systemctl --user stop "$unit" 2>/dev/null || true
          ;;
        *)
          echo "usage: sunshine-stream-inhibit do|undo" >&2
          exit 2
          ;;
      esac
    '';
  };

  # Sunshine notices an app quit, and runs its undo, only when asked for its state: by
  # the stream's control loop, which ends with the stream, or by a client's serverinfo
  # poll, which ends when Moonlight quits. Polled until the app is gone; the poll must
  # stay out of the app's process group, which Sunshine waits on (wait-all).
  pollUntilFree = pkgs.writeShellApplication {
    name = "sunshine-poll-until-free";
    runtimeInputs = [pkgs.curl];
    text = ''
      for _ in {1..30}; do
        state=$(curl -fsS http://localhost:47989/serverinfo || true)
        [[ $state == *SUNSHINE_SERVER_FREE* ]] && exit 0
        sleep 1
      done
      echo "Sunshine still reports an app running" >&2
      exit 1
    '';
  };

  # An app's command, for apps that should end with the stream. Sunshine keeps an app
  # running after its client disconnects, to resume it, and runs the prep commands' undo
  # only once the app quits; without this, closing Moonlight left the screens off. The
  # app quits when this exits, at a disconnect with no reconnect within the grace period,
  # so a dropped connection can resume the stream.
  untilDisconnect = pkgs.writeShellApplication {
    name = "sunshine-until-disconnect";
    runtimeInputs = [config.systemd.package];
    text = ''
      grace=30

      exec {log}< <(journalctl --user --unit sunshine --follow --lines 0 --output cat)
      journal=$!
      while read -r -u "$log" line; do
        if [[ $line != *"CLIENT DISCONNECTED"* ]]; then
          continue
        fi
        reconnected=false
        deadline=$((SECONDS + grace))
        while ((SECONDS < deadline)) && read -r -t "$((deadline - SECONDS))" -u "$log" line; do
          if [[ $line == *"CLIENT CONNECTED"* ]]; then
            reconnected=true
            break
          fi
        done
        if ! $reconnected; then
          break
        fi
      done
      kill "$journal" 2>/dev/null || true
      systemd-run --user --quiet --collect ${pollUntilFree}/bin/sunshine-poll-until-free
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
    settings = {
      # The headless output is only reachable through wlroots screencopy, and only the
      # RX 7900 XT encodes; set, Sunshine skips probing the XDG portal and NVENC at start.
      # Pinned by PCI path, as renderD128 and the iGPU's renderD129 follow probe order.
      capture = "wlr";
      encoder = "vaapi";
      adapter_name = "/dev/dri/by-path/pci-0000:03:00.0-render";
      global_prep_cmd = builtins.toJSON [
        {
          do = "${streamDisplay}/bin/sunshine-stream-display do";
          undo = "${streamDisplay}/bin/sunshine-stream-display undo";
        }
        {
          do = "${streamInhibit}/bin/sunshine-stream-inhibit do";
          undo = "${streamInhibit}/bin/sunshine-stream-inhibit undo";
        }
      ];
    };
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
  systemd.user.services.sunshine.serviceConfig.ExecStopPost = [
    "${streamDisplay}/bin/sunshine-stream-display undo"
    "${streamInhibit}/bin/sunshine-stream-inhibit undo"
  ];

  # Base port 47989 and its fixed offsets (the module's openFirewall list), less the web
  # UI's 47990. Streams from outside the house come over Tailscale, whose 100.64.0.0/10
  # addresses the LAN subnets don't cover.
  networking.firewall = let
    ports = {
      allowedTCPPorts = [47984 47989 48010];
      allowedUDPPorts = [47998 47999 48000 48002 48010];
    };
  in {
    lan = ports;
    interfaces.tailscale0 = ports;
  };

  # Moonlight wakes the host with a magic packet once idle has suspended it. The wired
  # profile is NetworkManager's own and leaves wake-on-lan at "default", so NM applies
  # this global default (64: magic packet) when it activates the link; without it the
  # r8169 NIC comes up with Wake-on: d. The BIOS must also allow waking from PCIe.
  networking.networkmanager.settings.connection."ethernet.wake-on-lan" = 64;
}
