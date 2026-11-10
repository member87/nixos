{pkgs, ...}: let
  # Print: freezes the screen, then a region is picked from the frozen frame
  # and opened in satty. hyprshot --freeze lifts the freeze as soon as slurp
  # exits, racing grim, so the capture could be of the live screen.
  screenshot = pkgs.writeShellApplication {
    name = "screenshot";
    runtimeInputs = with pkgs; [grim hyprpicker satty slurp wl-clipboard];
    text = ''
      # hyprpicker draws the frame it grabbed at start over every output
      hyprpicker --render-inactive --no-zoom --disable-preview --quiet &
      freeze=$!
      trap 'kill "$freeze" 2>/dev/null || true' EXIT
      # slurp has to map above the freeze, not under it
      sleep 0.2
      region=$(slurp -d) || exit 0
      # grim copies the frozen frame, so the freeze stays up until it is done;
      # satty's default thumbnail is a temp file deleted as --early-exit quits,
      # before the notification can show it: send its icon instead
      { grim -g "$region" -; kill "$freeze"; } |
        satty --fullscreen --early-exit --notification-thumbnail app-icon --copy-command wl-copy -f -
    '';
  };
in {
  home.pointerCursor = {
    enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Amber";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # Hyprland 0.57 reads only Lua (hyprland.lua); hyprlang configs are ignored
  # and replaced by its example. Options render as one hl.config({...}); the
  # binds are Lua below. The same API drives `hyprctl dispatch`, so callers
  # pass dispatchers too: hyprctl dispatch 'hl.dsp.exit()'.
  wayland.windowManager.hyprland = {
    configType = "lua";
    systemd.variables = ["--all"];
    enable = true;

    settings.config = {
      general = {
        gaps_in = 0;
        gaps_out = 0;
        border_size = 2;
        col = {
          active_border = {
            colors = ["rgb(fe8019)" "rgb(fabd2f)"];
            angle = 45;
          };
          inactive_border = "rgb(1d2021)";
        };
        allow_tearing = false;
        layout = "dwindle";
      };

      group = {
        col = {
          border_active = {
            colors = ["rgb(fe8019)" "rgb(fabd2f)"];
            angle = 45;
          };
          border_inactive = "rgb(1d2021)";
        };
        groupbar.col = {
          active = "rgb(fe8019)";
          inactive = "rgb(1d2021)";
        };
      };

      xwayland.force_zero_scaling = true;

      input = {
        kb_layout = "gb";
        follow_mouse = 1;
        sensitivity = 0;
        accel_profile = "flat";
      };

      decoration = {
        rounding = 4;
        active_opacity = 1.0;
        inactive_opacity = 1.0;
        shadow.enabled = false;
        blur.enabled = false;
      };

      animations.enabled = false;

      misc = {
        force_default_wallpaper = 0;
        # quickshell draws the wallpaper (desktop/Wallpaper.qml); before it
        # does, and while it restarts, the wallpaper's ground colour
        disable_hyprland_logo = true;
        background_color = 4280821800; # 0xff282828
        # a crashed lock screen leaves the session locked on a solid colour;
        # this lets a fresh one (loginctl lock-session from a tty) take over
        allow_session_lock_restore = true;
      };
    };

    extraConfig = ''
      -- every screen without a rule of its own: 10-bit, or HDR video (auto
      -- HDR, render.cm_auto_hdr) warns "wide color gamut is enabled but the
      -- display is not in 10-bit mode". While HDR video is up, SDR surfaces
      -- (subtitles, the player's controls) get white at sdr_max_luminance
      -- nits; the default 80 shows white text grey. A rule for a named output
      -- replaces this one, so it needs its own bitdepth and sdr_max_luminance.
      hl.monitor({
        output            = "",
        mode              = "preferred",
        position          = "auto",
        scale             = "auto",
        bitdepth          = 10,
        sdr_max_luminance = 250,
      })

      -- monitors.lua is written by nwg-displays and may not exist yet
      pcall(require, "monitors")

      -- Jellium (jellyfin-desktop) stays SDR in fullscreen. With auto HDR its
      -- mpv sends PQ, white at 203 nits on this OLED, much dimmer than the
      -- same film tone-mapped to SDR at the desktop's brightness. Games
      -- still switch the screen to HDR.
      hl.window_rule({ name = "jellium-sdr", match = { class = "^net.nullsum.JelliumDesktop$" }, no_auto_hdr = true })

      local mod = "SUPER"
      local function exec(cmd) return hl.dsp.exec_cmd(cmd) end

      hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
      hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

      -- the screenshot freeze (hyprpicker) stays above popups that open while
      -- a region is picked (notifications, OSDs), so they are not captured;
      -- slurp's selection stays above the freeze. A lower order is drawn
      -- higher; layers default to 0
      hl.layer_rule({ name = "screenshot-freeze", match = { namespace = "^hyprpicker$" }, order = -100 })
      hl.layer_rule({ name = "screenshot-selection", match = { namespace = "^selection$" }, order = -101 })
      hl.bind("Print", exec("${screenshot}/bin/screenshot"))
      hl.bind(mod .. " + Return", exec("ghostty"))
      hl.bind(mod .. " + SHIFT + Q", hl.dsp.window.close())
      for _, dir in ipairs({ "left", "right", "up", "down" }) do
        hl.bind(mod .. " + " .. dir, hl.dsp.focus({ direction = dir }))
        hl.bind(mod .. " + SHIFT + " .. dir, hl.dsp.window.move({ direction = dir }))
      end
      hl.bind(mod .. " + D", exec("vicinae open"))
      hl.bind(mod .. " + SHIFT + E", hl.dsp.exit())
      -- hypridle's lock_cmd starts the quickshell lock screen
      hl.bind(mod .. " + L", exec("loginctl lock-session"))
      hl.bind(mod .. " + F", hl.dsp.window.fullscreen())
      hl.bind(mod .. " + space", hl.dsp.window.float({ action = "toggle" }))
      hl.bind(mod .. " + W", hl.dsp.group.toggle())
      hl.bind(mod .. " + tab", hl.dsp.group.next())
      hl.bind(mod .. " + SHIFT + tab", hl.dsp.group.prev())

      -- Volume and media keys; the bar's OSD shows the change (volume it
      -- sees in PipeWire, brightness it is told about)
      hl.bind("XF86AudioRaiseVolume", exec("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"))
      hl.bind("XF86AudioLowerVolume", exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"))
      hl.bind("XF86AudioMute", exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
      hl.bind("XF86MonBrightnessUp", exec("brightnessctl -q set 5%+ && qs -c bar ipc call osd brightness"))
      hl.bind("XF86MonBrightnessDown", exec("brightnessctl -q set 5%- && qs -c bar ipc call osd brightness"))
      hl.bind("XF86AudioNext", exec("playerctl next"))
      hl.bind("XF86AudioPause", exec("playerctl play-pause"))
      hl.bind("XF86AudioPlay", exec("playerctl play-pause"))
      hl.bind("XF86AudioPrev", exec("playerctl previous"))

      -- workspaces 1-10 on the number row by keycode (10 is "1"), whatever
      -- the layout
      for i = 0, 9 do
        hl.bind(mod .. " + code:1" .. i, hl.dsp.focus({ workspace = i + 1 }))
        hl.bind(mod .. " + SHIFT + code:1" .. i, hl.dsp.window.move({ workspace = i + 1 }))
      end

      hl.bind(mod .. " + S", hl.dsp.submap("resize"))
      hl.define_submap("resize", function()
        hl.bind("right", hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true })
        hl.bind("left", hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true })
        hl.bind("up", hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true })
        hl.bind("down", hl.dsp.window.resize({ x = 0, y = 10, relative = true }), { repeating = true })
        hl.bind("escape", hl.dsp.submap("reset"))
      end)
    '';
  };
}
