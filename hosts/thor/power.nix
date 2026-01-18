{
  config,
  lib,
  pkgs,
  ...
}: {
  powerManagement.enable = true;

  boot.resumeDevice = "/dev/disk/by-uuid/79423f9e-f360-4279-a45e-2051edcaa0bc";
  boot.kernelParams = [
    "amd_pstate=active"
    "mem_sleep_default=deep"
    "processor.max_cstate=9"
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
  services.tlp.enable = false;

  powerManagement.resumeCommands = ''
    ${pkgs.systemd}/bin/systemctl restart auto-cpufreq
  '';

  environment.systemPackages = with pkgs; [
    auto-cpufreq
    powertop
    acpi
    lm_sensors
    smartmontools
    hdparm
  ];
}
