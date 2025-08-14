{pkgs, ...}: let
  fullscreenSpanScript = pkgs.writeShellScriptBin "hyprland-fullscreen-span" ''
           #!${pkgs.bash}/bin/bash


    JQ_CMD="${pkgs.jq}/bin/jq"

    if ! [ -x "$JQ_CMD" ]; then
      echo "Error: jq command not found or not executable at $JQ_CMD" >&2
      exit 1
    fi

    MONITORS_JSON=$(hyprctl -j monitors)

    if [ -z "$MONITORS_JSON" ] || [ "$MONITORS_JSON" == "null" ]; then
        echo "Error: Could not get monitor information from hyprctl or it is null." >&2
        exit 1
    fi

    IS_VALID_ARRAY=$($JQ_CMD 'if type=="array" and length > 0 then true else false end' <<< "$MONITORS_JSON")
    if [ "$IS_VALID_ARRAY" != "true" ]; then
        echo "Error: Monitor information is not a valid non-empty array." >&2
        exit 1
    fi

    FAR_LEFT_X=$(echo "$MONITORS_JSON" | $JQ_CMD 'map(.x) | min')

    if [ "$FAR_LEFT_X" == "null" ] || [ "$FAR_LEFT_X" == "" ]; then
        echo "Error: Could not determine the far left X coordinate of monitors." >&2
        exit 1
    fi

    FAR_RIGHT_EDGE_X=$(echo "$MONITORS_JSON" | $JQ_CMD 'map(.x + .width) | max')

    if [ "$FAR_RIGHT_EDGE_X" == "null" ] || [ "$FAR_RIGHT_EDGE_X" == "" ]; then
        echo "Error: Could not determine the far right edge X coordinate of monitors." >&2
        exit 1
    fi

    LEFTMOST_ANCHOR_MONITOR_INFO=$(echo "$MONITORS_JSON" | $JQ_CMD --argjson x_coord "$FAR_LEFT_X" \
      '[.[] | select(.x == $x_coord)][0]')

    if [ -z "$LEFTMOST_ANCHOR_MONITOR_INFO" ] || [ "$LEFTMOST_ANCHOR_MONITOR_INFO" == "null" ]; then
        echo "Error: Could not determine an anchor monitor at X=$FAR_LEFT_X." >&2
        exit 1
    fi

    TARGET_Y=$(echo "$LEFTMOST_ANCHOR_MONITOR_INFO" | $JQ_CMD '.y')
    TARGET_HEIGHT=$(echo "$LEFTMOST_ANCHOR_MONITOR_INFO" | $JQ_CMD '.height | round')

    if [ "$TARGET_Y" == "null" ] || [ "$TARGET_Y" == "" ]; then
        echo "Error: Extracted anchor monitor Y coordinate is invalid or empty." >&2
        exit 1
    fi

    if [ "$TARGET_HEIGHT" == "null" ] || [ "$TARGET_HEIGHT" == "" ]; then
        echo "Error: Extracted anchor monitor height is null or empty." >&2
        exit 1
    fi

    if ! [[ "$TARGET_HEIGHT" =~ ^[0-9]+$ ]] || [ "$TARGET_HEIGHT" -le 0 ]; then
        echo "Error: Extracted anchor monitor height is not a positive number (Height: $TARGET_HEIGHT)." >&2
        exit 1
    fi

    TARGET_WIDTH=$((FAR_RIGHT_EDGE_X - FAR_LEFT_X))

    if ! [[ "$TARGET_WIDTH" =~ ^-?[0-9]+$ ]]; then
        echo "Error: Calculated target width is not a number (Width: $TARGET_WIDTH)." >&2
        exit 1
    fi

    if [ "$TARGET_WIDTH" -le 0 ]; then
        echo "Error: Calculated target width is zero or negative (Width: $TARGET_WIDTH)." >&2
        exit 1
    fi

    hyprctl --batch \
        "dispatch setfloating active;" \
        "dispatch movewindowpixel exact $FAR_LEFT_X $TARGET_Y;" \
        "dispatch resizewindowpixel exact $TARGET_WIDTH $TARGET_HEIGHT"

    echo "Window manipulation complete."


  ''; # End of script string
in {
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

      layerrule = ["blur, bar"];
      bezier = ["mycurve,.32,.97,.53,.98"];

      debug = {full_cm_proto = true;};

      animations = {
        enabled = 0;
        animation = [
          "windowsMove,1,4,mycurve"
          "windowsIn,1,4,mycurve"
          "windowsOut,0,4,mycurve"
        ];
      };

      debug = {disable_logs = true;};

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
          "$mod, space, togglefloating"
          "$mod, w, togglegroup"
          "$mod, tab, changegroupactive"
          "$mod SHIFT, tab, changegroupactive, b"

          "$mod ALT, S, exec, ${fullscreenSpanScript}/bin/hyprland-fullscreen-span"

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
