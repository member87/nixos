{
  config,
  pkgs,
  ...
}: let
  agsEnabled = config.programs.ags.enable or false;
  agsQuitCmd =
    if agsEnabled
    then "killall gjs; "
    else "";
  agsRunCmd =
    if agsEnabled
    then "; ags run"
    else "";
in {
  services.hypridle = {
    enable = true;

    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "${agsQuitCmd}loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on${agsRunCmd}";
      };

      listener = [
        {
          timeout = 300;
          on-timeout = "${agsQuitCmd}loginctl lock-session";
        }
        {
          timeout = 1200;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on${agsRunCmd}";
        }
        {
          timeout = 1800;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };
}
