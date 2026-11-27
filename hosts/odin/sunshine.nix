# Sunshine game-stream host for Moonlight clients. Runs as a user service in the
# Hyprland session; pair clients in the web UI at https://localhost:47990, which only
# this machine can reach. Its settings and apps pages are read-only: `settings` and
# `applications` below make the module start Sunshine with both from the store. Pairing
# and credentials stay in ~/.config/sunshine.
{
  config,
  lib,
  pkgs,
  username,
  ...
}: let
  hm = config.home-manager.users.${username};
  # the quickshell lock screen hypridle's lock_cmd starts (home/common/desktop/hypridle.nix)
  lockScreen = "${hm.programs.quickshell.package}/bin/qs -n -p ${hm.xdg.configHome}/quickshell/bar/lock.qml";

  # Streams go to a headless output sized to the client, so a 16:9 client gets a 16:9
  # desktop instead of the 3440x1440 ultrawide letterboxed. The physical screens are
  # turned off for the stream: their workspaces move to the headless output, and it is
  # then the only wl_output, the one Sunshine captures (output_name pins it too).
  streamDisplay = pkgs.writeShellApplication {
    name = "sunshine-stream-display";
    runtimeInputs = [config.programs.hyprland.package pkgs.jq];
    text = ''
      output=SUNSHINE

      case "''${1:-}" in
        do)
          # Sunshine undoes only the prep commands before a failed one, so a failure
          # part-way, the screens already off, is undone here.
          trap '"$0" undo' ERR

          # Sunshine passes the client's requested mode to prep commands. The output
          # refreshes at twice the stream's rate: from 1.5x, Sunshine copies each frame as
          # the compositor draws it instead of on its own clock, which repeated frames.
          width=''${SUNSHINE_CLIENT_WIDTH:-1920}
          height=''${SUNSHINE_CLIENT_HEIGHT:-1080}
          mode="''${width}x''${height}@$((''${SUNSHINE_CLIENT_FPS:-60} * 2))"

          # A 4K client gets the desktop at 2560x1440's size, the TV across the room at
          # 1920x1080's. Hyprland takes only scales that divide the mode into whole pixels.
          scale=1
          if ((height == 2160)); then
            scale=1.5
            if [[ ''${SUNSHINE_CLIENT_NAME:-} == TV ]]; then
              scale=2
            fi
          fi

          # A stream that ended without its undo (Sunshine crashed) leaves one behind.
          hyprctl -q output remove "$output" || true
          hyprctl -q output create headless "$output"
          hyprctl -q eval "hl.monitor({ output = \"$output\", mode = \"$mode\", position = \"auto\", scale = $scale })"

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
  # app quits when this exits: when no client has been connected for the grace period,
  # so a dropped connection can resume the stream and a second viewer keeps it going.
  untilDisconnect = pkgs.writeShellApplication {
    name = "sunshine-until-disconnect";
    runtimeInputs = [config.systemd.package];
    text = ''
      grace=30
      clients=0

      # Sunshine's own lines only: Steam and the games it starts log into this unit too.
      # The backlog covers this app's launch, and counting starts over at each launch
      # line, so it counts from the one that ran this script.
      exec {log}< <(journalctl --user --unit sunshine SYSLOG_IDENTIFIER=sunshine --follow --lines 200 --output cat)
      journal=$!
      deadline=$((SECONDS + grace))
      while :; do
        if ((clients > 0)); then
          read -r -u "$log" line || break
        else
          ((SECONDS < deadline)) || break
          read -r -t "$((deadline - SECONDS))" -u "$log" line || break
        fi
        case $line in
          *"]: Info: Executing: [$0]"*)
            clients=0
            deadline=$((SECONDS + grace))
            ;;
          *"]: Info: CLIENT CONNECTED")
            clients=$((clients + 1))
            ;;
          # A session Sunshine ends on its ping check (a client gone without a word, or
          # one that never connected) logs no CLIENT DISCONNECTED.
          *"]: Info: CLIENT DISCONNECTED" | *"Ping Timeout")
            if ((clients > 0)); then
              clients=$((clients - 1))
            fi
            if ((clients == 0)); then
              deadline=$((SECONDS + grace))
            fi
            ;;
        esac
      done
      kill "$journal" 2>/dev/null || true
      systemd-run --user --quiet --collect ${pollUntilFree}/bin/sunshine-poll-until-free
    '';
  };

  # A stream starts on whatever the session was left at, often the lock screen: suspend
  # locks it first, and hypridle after 5 minutes idle. It is unlocked for the stream, the
  # client's pairing standing in for the password, and locked again when the stream
  # ends. Last in global_prep_cmd: undo runs in reverse, so the physical screens are off
  # by the unlock and still off at the lock.
  streamLock = pkgs.writeShellApplication {
    name = "sunshine-stream-lock";
    runtimeInputs = [config.programs.hyprland.package config.systemd.package hm.programs.quickshell.package pkgs.jq];
    text = ''
      lock() {
        loginctl lock-session
        # lock-session only asks hypridle to start the lock screen, and the physical
        # screens come on next: wait until Hyprland holds the lock, so they never show
        # the session unlocked
        for _ in {1..50}; do
          if [[ $(qs -p ${hm.xdg.configHome}/quickshell/bar/lock.qml ipc call lock secure 2>/dev/null) == true ]]; then
            return
          fi
          sleep 0.1
        done
        echo "the lock screen did not confirm the lock" >&2
      }

      case "''${1:-}" in
        do)
          # logind's Unlock reaches the lock screen through hypridle's unlock_cmd; a
          # failure must not abort the launch
          loginctl unlock-session || true
          ;;
        undo)
          lock
          ;;
        stopped)
          # ExecStopPost runs at every stop and restart: lock only if a stream was cut off
          hyprctl monitors all -j 2>/dev/null |
            jq -e 'any(.[]; .name == "SUNSHINE")' >/dev/null || exit 0
          lock
          ;;
        *)
          echo "usage: sunshine-stream-lock do|undo|stopped" >&2
          exit 2
          ;;
      esac
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
    # The module's wrapper, for CAP_SYS_NICE alone: with it Sunshine gets the high-priority
    # EGL context it asks for, so its colour conversion is not queued behind a game that
    # saturates the GPU. CAP_SYS_ADMIN is only for KMS capture, which isn't used. Sunshine
    # drops the capability once its EGL worker thread holds it.
    capSysAdmin = true;
    settings = {
      # The headless output is only reachable through wlroots screencopy, and only the
      # RX 7900 XT encodes; set, Sunshine skips probing the XDG portal and NVENC at start.
      # Pinned by PCI path, as renderD128 and the iGPU's renderD129 follow probe order.
      capture = "wlr";
      encoder = "vaapi";
      adapter_name = "/dev/dri/by-path/pci-0000:03:00.0-render";
      # The stream display; without it Sunshine takes the first output, which is the
      # ultrawide if disabling it hasn't taken effect yet.
      output_name = "SUNSHINE";
      # CBR with the standard VBV buffer let scene changes produce frames too large for
      # FEC, which Sunshine then sent unprotected ("Skipping FEC for abnormally large
      # encoded frame").
      vaapi_strict_rc_buffer = "enabled";
      # Sunshine counts Tailscale's 100.64.0.0/10 as LAN; the firewall keeps 47990 closed
      # too, this holds if it ever opens.
      origin_web_ui_allowed = "pc";
      # The stream shows an unlocked desktop: encrypted on the LAN too, for clients that
      # support it. Tailscale streams count as LAN and are encrypted twice; cheap at these
      # bitrates.
      lan_encryption_mode = 1;
      global_prep_cmd = builtins.toJSON [
        {
          do = "${streamDisplay}/bin/sunshine-stream-display do";
          undo = "${streamDisplay}/bin/sunshine-stream-display undo";
        }
        {
          do = "${streamInhibit}/bin/sunshine-stream-inhibit do";
          undo = "${streamInhibit}/bin/sunshine-stream-inhibit undo";
        }
        {
          do = "${streamLock}/bin/sunshine-stream-lock do";
          undo = "${streamLock}/bin/sunshine-stream-lock undo";
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

  security.wrappers.sunshine.capabilities = lib.mkForce "cap_sys_nice+p";

  # If Sunshine crashes mid-stream, no undo runs. Locked first, while the screens are off.
  systemd.user.services.sunshine.serviceConfig.ExecStopPost = [
    "${streamLock}/bin/sunshine-stream-lock stopped"
    "${streamDisplay}/bin/sunshine-stream-display undo"
    "${streamInhibit}/bin/sunshine-stream-inhibit undo"
  ];
  # radeonsi's VA-API encoder uses VCN's low-latency mode only with this flag (Mesa
  # docs/envvars.rst): about 0.1 ms less per 1440p frame here, the same output.
  systemd.user.services.sunshine.environment.AMD_DEBUG = "lowlatencyenc";

  # libvirtualhid builds DualSense, DualShock 4 and Switch pads, and native Xbox HID ones,
  # on /dev/uhid. The node exists before the module loads, root-only, so the udev rules'
  # uaccess never applied and Xbox pads fell back to uinput. Loaded at boot, its add event
  # gives the session user the node (the Virtual FIDO2 rule in default.nix needs it too).
  boot.kernelModules = ["uhid"];

  # Sunshine runs in the user's session, so after a reboot Moonlight found odin offline
  # until someone logged in at the desk. greetd logs in once per boot without a password,
  # and Hyprland starts the lock screen before anything else; after a logout the greeter
  # asks as before. With no password at login the keyring starts locked; typing the
  # password on the lock screen unlocks it (its PAM stack has pam_gnome_keyring, greeter.nix).
  services.greetd.settings.initial_session = {
    command = "${pkgs.writeShellScript "hyprland-locked" ''
      export LOCK_AT_START=1
      exec ${config.programs.hyprland.package}/bin/start-hyprland
    ''}";
    user = username;
  };
  home-manager.users.${username}.wayland.windowManager.hyprland.extraConfig = ''
    -- LOCK_AT_START: the boot-time autologin (hosts/odin/sunshine.nix)
    hl.on("hyprland.start", function()
      hl.exec_cmd('[ "$LOCK_AT_START" = 1 ] && exec ${lockScreen}')
    end)
  '';

  # Base port 47989 and its fixed offsets that Sunshine listens on: TCP 47984, 47989 and
  # RTSP's 48010, UDP 47998-48000 (video, control, audio). The web UI's 47990 stays
  # closed. Streams from outside the house come over Tailscale, whose 100.64.0.0/10
  # addresses the LAN subnets don't cover.
  networking.firewall = let
    ports = {
      allowedTCPPorts = [47984 47989 48010];
      allowedUDPPorts = [47998 47999 48000];
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
