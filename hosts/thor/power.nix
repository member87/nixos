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

  # Panel power savings (amdgpu ABM: the backlight dimmed, the image
  # brightened to make up for it; levels 0-4, stronger dims further). The
  # daemon's own action waits for 50% charge even in power-saver, and its
  # thresholds are fixed; the kernel lets one writer own the setting, so the
  # action stays off ("-": a failure leaves the daemon running) and
  # panel-power-savings below sets it instead.
  systemd.services.power-profiles-daemon.serviceConfig.ExecStartPost = "-${config.services.power-profiles-daemon.package}/bin/powerprofilesctl configure-action amdgpu_panel_power --disable";

  # On battery: power-saver 2, 3 at 20% and below; balanced 1 below 30%;
  # performance 0. On the charger 0. Re-evaluated on every UPower or
  # power-profiles-daemon signal, and each minute in case a resume resets it.
  systemd.services.panel-power-savings = {
    description = "amdgpu panel power savings from the power profile and battery";
    wantedBy = ["multi-user.target"];
    after = ["upower.service" "power-profiles-daemon.service"];
    wants = ["upower.service" "power-profiles-daemon.service"];
    path = [pkgs.glib pkgs.systemd pkgs.coreutils];
    serviceConfig.Restart = "on-failure";
    script = ''
      prop() { busctl --system get-property "$@" | cut -d' ' -f2- | tr -d '"'; }

      level() {
        [ "$(prop org.freedesktop.UPower /org/freedesktop/UPower org.freedesktop.UPower OnBattery)" = true ] || { echo 0; return; }
        pct=$(prop org.freedesktop.UPower /org/freedesktop/UPower/devices/DisplayDevice org.freedesktop.UPower.Device Percentage)
        pct=''${pct%.*}
        case "$(prop org.freedesktop.UPower.PowerProfiles /org/freedesktop/UPower/PowerProfiles org.freedesktop.UPower.PowerProfiles ActiveProfile)" in
          power-saver) if [ "$pct" -le 20 ]; then echo 3; else echo 2; fi ;;
          balanced) if [ "$pct" -lt 30 ]; then echo 1; else echo 0; fi ;;
          *) echo 0 ;;
        esac
      }

      apply() {
        l=$(level) || return 0
        for f in /sys/class/drm/card*-eDP-*/amdgpu/panel_power_savings; do
          [ -e "$f" ] && [ "$(cat "$f")" != "$l" ] && echo "$l" > "$f" && echo "$f: $l"
        done
        return 0
      }

      apply
      { gdbus monitor --system --dest org.freedesktop.UPower &
        gdbus monitor --system --dest org.freedesktop.UPower.PowerProfiles &
        wait; } | while :; do
        read -r -t 60 _; rc=$?
        # EOF: a monitor died; systemd restarts the unit
        [ $rc -eq 0 ] || [ $rc -gt 128 ] || exit 1
        # a change arrives as a burst of signals: settle, then apply once
        while read -r -t 0.3 _; do :; done
        apply
      done
    '';
  };

  environment.systemPackages = with pkgs; [
    powertop
    acpi
    lm_sensors
    smartmontools
    hdparm
  ];
}
