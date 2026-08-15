{pkgs, ...}: {
  programs.hyprlock = {
    enable = true;

    settings = {
      auth = {
        "fingerprint:enabled" = true;
      };

      background = {
        path = "screenshot";
        blue_passes = 1;
        color = "rgba(29, 32, 33, 1.0)";
        blur_passes = 4;
        noise = 0.008;
        brightness = 0.5;
      };

      input-field = {
        size = "200, 50";
        hide_input = false;
        position = "0, -20";
        halign = "center";
        valign = "center";
        placeholder_text = "Password...";
        fade_on_empty = false;
        font_color = "rgb(235, 219, 178)";
        inner_color = "rgb(60, 56, 54)";
      };

      label = [
        {
          text = "Hello, $USER";
          position = "0, 80";
          halign = "center";
          valign = "center";
          color = "rgb(235, 219, 178)";
        }
        {
          text = "cmd[update:1000] date +\"%H:%M\"";
          position = "0, 200";
          font_size = 100;
          halign = "center";
          valign = "center";
          color = "rgb(235, 219, 178)";
        }
      ];
    };
  };
}
