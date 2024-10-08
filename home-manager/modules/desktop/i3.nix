{lib, ...}: let
  mod = "Mod4";
in {
  xsession.windowManager.i3 = {
    enable = true;
    config = {
      terminal = "alacritty";
      modifier = "Mod4";

      window = {
        hideEdgeBorders = "smart";
        titlebar = false;
      };

      startup = [
        {
          command = "systemctl restart --user polybar";
        }
      ];

      keybindings = lib.mkOptionDefault {
        "${mod}+d" = "exec rofi -show drun";
      };

      bars = [];
    };
  };
}
