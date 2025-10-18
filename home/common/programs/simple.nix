{
  lib,
  config,
  ...
}: {
  programs = {
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    mangohud = {
      enable = true;
      enableSessionWide = true;

      settings = {
        hud_compact = true;
        position = "top-left";
        frame_timing = false;
        frametime = false;
        hud_no_margin = true;
        width = 80;
        table_columns = 2;
        font_size = 20;
      };
    };
  };
}
