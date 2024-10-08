{...}: {
  wayland.windowManager.hyprland.settings = {
    "$mod" = "SUPER";

    bindm = [
      "$mod, ENTER, exec, alacritty"
    ];
  };
}
