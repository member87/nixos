{
  config,
  osConfig,
  ...
}: let
  # the lock screen is a second quickshell shell next to the bar
  # (home/common/desktop/quickshell)
  qs = "${config.programs.quickshell.package}/bin/qs";
  lockShell = "${config.xdg.configHome}/quickshell/bar/lock.qml";
in {
  services.hypridle = {
    enable = true;

    settings = {
      general = {
        # -n: no second copy while locked
        lock_cmd = "${qs} -n -p ${lockShell}";
        # logind's Unlock (`loginctl unlock-session`, as Sunshine's stream start sends on
        # odin) ends the lock as a correct password would (lock.qml)
        unlock_cmd = "${qs} -p ${lockShell} ipc call lock unlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch 'hl.dsp.dpms({ action = \"on\" })'";
      };

      listener = [
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 1200;
          on-timeout = "hyprctl dispatch 'hl.dsp.dpms({ action = \"off\" })'";
          on-resume = "hyprctl dispatch 'hl.dsp.dpms({ action = \"on\" })'";
        }
        {
          timeout = 1800;
          # hibernates after logind's HibernateDelaySec where the host can
          # resume (thor), as the lid does; plain suspend elsewhere (odin)
          on-timeout =
            if osConfig.boot.resumeDevice != ""
            then "systemctl suspend-then-hibernate"
            else "systemctl suspend";
        }
      ];
    };
  };
}
