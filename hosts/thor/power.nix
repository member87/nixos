{
  config,
  lib,
  pkgs,
  ...
}: {
  powerManagement.enable = true;

  services.logind = {
    settings = {
      Login = {
        HandleLidSwitch = "suspend";
        HandleLidSwitchExternalPower = "suspend";
        HandleLidSwitchDocked = "ignore";
        HandlePowerKey = "suspend";
        IdleAction = "suspend";
        IdleActionSec = "20m";
      };
    };
  };

  services.auto-cpufreq = {
    enable = true;
    settings = {
      battery = {
        governor = "schedutil";
        turbo = "auto";
      };
      charger = {
        governor = "schedutil";
        turbo = "auto";
      };
    };
  };

  services.power-profiles-daemon.enable = false;
  services.thermald.enable = true;

  systemd.sleep.extraConfig = ''
    HibernateDelaySec=1h
    SuspendState=mem
  '';

  powerManagement.resumeCommands = ''
    ${pkgs.systemd}/bin/systemctl restart NetworkManager
    ${pkgs.systemd}/bin/systemctl restart auto-cpufreq
  '';

  boot.resumeDevice = "/dev/disk/by-uuid/79423f9e-f360-4279-a45e-2051edcaa0bc";

  boot.kernelParams = [
    "amd_pstate=active"
    "mem_sleep_default=deep"
    "processor.max_cstate=9"
    "resume_offset=2140160"
  ];

  environment.systemPackages = with pkgs; [
    auto-cpufreq
    powertop
    acpi
    lm_sensors
    smartmontools
    hdparm
  ];
}
