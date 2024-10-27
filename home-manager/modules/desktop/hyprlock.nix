{
  ...
}:
{
  programs.hyprlock = {
    enable = true;

    settings = {
      background = {
        color = "rgba(10, 10, 10, 1.0)";
      };

      input-field = {
        size = "200, 50";
        hide_input = false;
        position = "0, -20";
        halign = "center";
        valign = "center";
        placeholder_text = "Password...";
        fade_on_empty = false;
        font_color = "rgb(245, 194, 231)";
        inner_color = "rgb(49, 50, 68)";
      };

      label = [
        {
          text = "Hello, $USER";
          position = "0, 80";
          halign = "center";
          valign = "center";
        }
        {
          text = "cmd[update:1000] date +\"%H:%M\"";
          position = "0, 200";
          font_size = 100;
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
