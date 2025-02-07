{
  lib,
  config,
  ...
}:
{
  services.dunst = {
    enable = true;
    settings = lib.mkForce {
      global = {
        width = "(300, 400)";
        padding = 12;
        frame_width = 0;
        horizontal_padding = 12;
        text_icon_padding = 18;
        separator_height = 2;
        line_height = 0;
        font = "FiraCode Nerd Font 11";
        markup = "full";
        format = "<b>%s</b>\n%b";
        alignment = "center";
        icon_path = "";
        corner_radius = 4;
        offset = "5x5";
        min_icon_size = 0;
        max_icon_size = 64;
        follow = "mouse";
      };

      urgency_low = {
        background = "#11111b";
        foreground = "#ffffff";
        timeout = 10;
      };

      urgency_normal = {
        background = "#11111b";
        foreground = "#ffffff";
        timeout = 10;
      };
    };
  };
}
