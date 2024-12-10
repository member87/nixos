{pkgs, ...}: {
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$mod" = "SUPER";

      monitor = [
        "HDMI-A-1, 1920x1080, 0x0, 1"
        "DP-1, 1920x1080@165, 1929x0, 1"
        "DP-2, 1920x1080, 3840x0, 1"
      ];

      general = {
        gaps_in = 0;
        gaps_out = 0;
        border_size = 2;

        "col.active_border" = "rgba(f2cdcdff) rgba(cba6f7ff) 45deg";
        "col.inactive_border" = "rgba(595959aa)";

        allow_tearing = false;
        layout = "dwindle";
      };

      input = {
        kb_layout = "gb";
        follow_mouse = 1;
        sensitivity = 0;
      };

      decoration = {
        rounding = 4;
        active_opacity = 1.0;
        inactive_opacity = 0.95;

        drop_shadow = true;
        shadow_range = 4;
        shadow_render_power = 3;
        "col.shadow" = "rgba(1a1a1aee)";

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
           

      bind =
      [
        ", Print, exec, ~/scripts/screenshot"
        "$mod, Return, exec, alacritty"
        "$mod SHIFT, Q, killactive"
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
        "$mod SHIFT, left, movewindow, l"
        "$mod SHIFT, right, movewindow, r"
        "$mod SHIFT, up, movewindow, u"
        "$mod SHIFT, down, movewindow, d"
        "$mod, d, exec, wofi --show run"
        "$mod SHIFT, e, exit"
        "$mod, l, exec, hyprlock"
        "$mod, mouse:272, movewindow"
        "$mod, f, fullscreen"
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPause, exec, playerctl play-pause"
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioPrev, exec, playerctl previous"

      ]
      ++ (
        # workspaces
        # binds $mod + [shift +] {1..9} to [move to] workspace {1..9}
        builtins.concatLists (builtins.genList (i:
            let ws = i + 1;
            in [
              "$mod, code:1${toString i}, workspace, ${toString ws}"
              "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
            ]
          )
          10)
      );
    };
  };
}
