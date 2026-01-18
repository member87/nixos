{pkgs, ...}: {
  home.pointerCursor = {
    package = pkgs.rose-pine-cursor;
    name = "BreezeX-RosePine-Linux";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  services.swayosd.enable = true;

  wayland.windowManager.hyprland = {
    systemd.variables = ["--all"];
    enable = true;

    settings = {
      "$mod" = "SUPER";

      monitor = [
        "HDMI-A-1, 1920x1080@60, 0x0, 1"
        "DP-1, 1920x1080@165, 1920x0, 1"
        "DP-2, 1920x1080@60, 3840x0, 1"
        "eDP-1, 2880x1920@120, 0x0, 2"
        "eDP-1, 2880x1920@120.0, 1651x1080, 2.0"
        "DP-4, 1920x1080@60.0, 1440x0, 1.0"
        # ", 1920x1080@60, auto, 1, mirror, eDP-1"
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

      group = {
        "col.border_active" = "rgb(f6c177) rgb(ebbcba) 45deg";
        "col.border_inactive" = "rgb(191724)";
        groupbar = {
          "col.active" = "rgb(f6c177)";
          "col.inactive" = "rgb(191724)";
        };
      };

      xwayland.force_zero_scaling = true;

      env = ["HYPRCURSOR_THEME,rose-pine-hyprcursor"];

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

      exec-once = [
        "eww open-many bar bar1 bar2"
        "lxqt-policykit-agent"
      ];

      layerrule = ["blur on"];

      animations = {
        enabled = 0;
      };

      misc = {
        force_default_wallpaper = 0;
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
          "$mod, d, exec, wofi --show drun"
          "$mod SHIFT, e, exit"
          "$mod, l, exec, hyprlock"
          "$mod, f, fullscreen"
          "$mod, space, togglefloating"
          "$mod, w, togglegroup"
          "$mod, tab, changegroupactive"
          "$mod SHIFT, tab, changegroupactive, b"

          # Volume and media keys
          ", XF86AudioRaiseVolume, exec, swayosd-client --output-volume raise"
          ", XF86AudioLowerVolume, exec, swayosd-client --output-volume lower"
          ", XF86AudioMute, exec, swayosd-client --output-volume mute-toggle"
          ", XF86MonBrightnessUp, exec, swayosd-client --brightness raise"
          ", XF86MonBrightnessDown, exec, swayosd-client --brightness lower"
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
