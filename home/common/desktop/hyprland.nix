{pkgs, ...}: {
  home.pointerCursor = {
    package = pkgs.rose-pine-cursor;
    name = "BreezeX-RosePine-Linux";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  wayland.windowManager.hyprland = {
    systemd.variables = ["--all"];
    enable = true;
    settings = {
      "$mod" = "SUPER";

      monitor = [
        "HDMI-A-1, 1920x1080@60, 0x0, 1"
        "DP-1, 1920x1080@165, 1920x0, 1"
        "DP-2, 1920x1080@60, 3840x0, 1"
      ];

      general = {
        gaps_in = 0;
        gaps_out = 0;
        border_size = 2;

        "col.active_border" = "rgb(f6c177) rgb(ebbcba) 45deg";
        "col.inactive_border" = "rgb(191724)";

        allow_tearing = false;
        layout = "dwindle";
      };

      env = [
        "HYPRCURSOR_THEME,rose-pine-hyprcursor"
      ];

      input = {
        kb_layout = "gb";
        follow_mouse = 1;
        sensitivity = 0;
        accel_profile = "flat";
      };

      decoration = {
        rounding = 4;
        active_opacity = 1.0;
        inactive_opacity = 0.95;

        blur = {
          enabled = true;
          size = 3;
          passes = 2;
          vibrancy = 0.1696;
        };
      };

      exec-once = [
        "eww open-many bar bar1 bar2"
        "lxqt-policykit-agent"
      ];

      layerrule = [
        "blur, bar"
      ];

      bezier = [
        "mycurve,.32,.97,.53,.98"
      ];

      animations = {
        enabled = 0;
        animation = [
          "windowsMove,1,4,mycurve"
          "windowsIn,1,4,mycurve"
          "windowsOut,0,4,mycurve"
        ];
      };

      debug = {
        disable_logs = true;
      };

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      bind =
        [
          ", Print, exec, ~/scripts/screenshot"
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
          "$mod, d, exec, wofi --show drun"
          "$mod SHIFT, e, exit"
          "$mod, l, exec, hyprlock"
          "$mod, f, fullscreen"
          ", XF86AudioNext, exec, playerctl next"
          ", XF86AudioPause, exec, playerctl play-pause"
          ", XF86AudioPlay, exec, playerctl play-pause"
          ", XF86AudioPrev, exec, playerctl previous"
        ]
        ++ (
          # workspaces
          # binds $mod + [shift +] {1..9} to [move to] workspace {1..9}
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
