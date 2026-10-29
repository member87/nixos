{pkgs, ...}: {
  home.pointerCursor = {
    enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Amber";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  wayland.windowManager.hyprland = {
    configType = "hyprlang";
    systemd.variables = ["--all"];
    enable = true;

    settings = {
      "$mod" = "SUPER";

      general = {
        gaps_in = 0;
        gaps_out = 0;
        border_size = 2;
        "col.active_border" = "rgb(fe8019) rgb(fabd2f) 45deg";
        "col.inactive_border" = "rgb(1d2021)";
        allow_tearing = false;
        layout = "dwindle";
      };

      group = {
        "col.border_active" = "rgb(fe8019) rgb(fabd2f) 45deg";
        "col.border_inactive" = "rgb(1d2021)";
        groupbar = {
          "col.active" = "rgb(fe8019)";
          "col.inactive" = "rgb(1d2021)";
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
        inactive_opacity = 1.95;
        shadow.enabled = false;
        blur = {
          enabled = false;
          size = 3;
          passes = 2;
          vibrancy = 0.1696;
        };
      };

      animations = {
        enabled = 0;
      };

      misc = {
        force_default_wallpaper = 0;
        # a crashed lock screen leaves the session locked on a solid colour;
        # this lets a fresh one (loginctl lock-session from a tty) take over
        allow_session_lock_restore = true;
      };

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      bind =
        [
          ", Print, exec, hyprshot -m region --raw | satty --fullscreen --early-exit --copy-command \"wl-copy\" -f -"
          "$mod, Return, exec, ghostty"
          "$mod SHIFT, Q, killactive"
          "$mod, left, movefocus, l"
          "$mod, right, movefocus, r"
          "$mod, up, movefocus, u"
          "$mod, down, movefocus, d"
          "$mod SHIFT, left, movewindow, l"
          "$mod SHIFT, right, movewindow, r"
          "$mod SHIFT, up, movewindow, u"
          "$mod SHIFT, down, movewindow, d"
          "$mod, d, exec, vicinae open"
          "$mod SHIFT, e, exit"
          # hypridle's lock_cmd starts the quickshell lock screen
          "$mod, l, exec, loginctl lock-session"
          "$mod, f, fullscreen"
          "$mod, space, togglefloating"
          "$mod, w, togglegroup"
          "$mod, tab, changegroupactive"
          "$mod SHIFT, tab, changegroupactive, b"

          # Volume and media keys; the bar's OSD shows the change (volume it
          # sees in PipeWire, brightness it is told about)
          ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
          ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
          ", XF86MonBrightnessUp, exec, brightnessctl -q set 5%+ && qs -c bar ipc call osd brightness"
          ", XF86MonBrightnessDown, exec, brightnessctl -q set 5%- && qs -c bar ipc call osd brightness"
          ", XF86AudioNext, exec, playerctl next"
          ", XF86AudioPause, exec, playerctl play-pause"
          ", XF86AudioPlay, exec, playerctl play-pause"
          ", XF86AudioPrev, exec, playerctl previous"
        ]
        ++ (
          # workspaces
          builtins.concatLists (
            builtins.genList (
              i: let
                ws = i + 1;
              in [
                "$mod, code:1${toString i}, workspace, ${toString ws}"
                "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
              ]
            )
            10
          )
        );
    };

    extraConfig = ''
      # monitors.conf is written by nwg-displays and may not exist yet;
      # noerror makes the source a no-op instead of a config error when missing.
      # hyprlang noerror true
      source = ~/.config/hypr/monitors.conf
      # hyprlang noerror false

      bind = $mod, S, submap, resize

      submap = resize
      binde = , right, resizeactive, 10 0
      binde = , left, resizeactive, -10 0
      binde = , up, resizeactive, 0 -10
      binde = , down, resizeactive, 0 10
      bind = , escape, submap, reset
      submap = reset
    '';
  };
}
