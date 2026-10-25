{
  config,
  pkgs,
  ...
}: {
  services.hypridle = {
    enable = true;

    settings = {
      general = {
        # the lock screen is a second quickshell shell next to the bar
        # (home/common/desktop/quickshell); -n: no second copy while locked
        lock_cmd = "${config.programs.quickshell.package}/bin/qs -n -p ${config.xdg.configHome}/quickshell/bar/lock.qml";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };

      listener = [
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 1200;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
        {
          timeout = 1800;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };
}
