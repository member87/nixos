{
  config,
  pkgs,
  ...
}: {
  powerManagement.enable = true;

  boot.resumeDevice = "/dev/disk/by-uuid/79423f9e-f360-4279-a45e-2051edcaa0bc";
  # nixos-hardware's framework-amd-ai-300-series module already sets
  # amd_pstate=active; this board only supports s2idle, so no mem_sleep_default
  boot.kernelParams = [
    "resume_offset=2140160"
  ];

  services.logind = {
    settings = {
      Login = {
        HibernateDelaySec = "3600";
        HandleLidSwitch = "suspend-then-hibernate";
      };
    };
  };

  # Framework's supported power manager: each profile sets the firmware power
  # slider (platform_profile, which drives amd-pmf's power limits) and the
  # amd-pstate EPP together. Switched from the quickshell system menu or
  # `powerprofilesctl set <power-saver|balanced|performance>`.
  services.power-profiles-daemon.enable = true;
  # the unit is only D-Bus activated; start it at boot so the saved profile is
  # restored before anything asks for it
  systemd.services.power-profiles-daemon.wantedBy = ["graphical.target"];
  # amdgpu panel power savings (ABM: backlight down, contrast up) ships
  # disabled; enabled it follows the profile and the charge, from none above
  # 50% up to level 3 below 20% in power-saver. The daemon keeps the setting
  # in its state file; this sets it after each start (Type=dbus: the name is
  # up). "-": a failure leaves the daemon running.
  systemd.services.power-profiles-daemon.serviceConfig.ExecStartPost = "-${config.services.power-profiles-daemon.package}/bin/powerprofilesctl configure-action amdgpu_panel_power --enable";

  environment.systemPackages = with pkgs; [
    powertop
    acpi
    lm_sensors
    smartmontools
    hdparm
  ];
}
