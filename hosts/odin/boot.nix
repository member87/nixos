{
  pkgs,
  lib,
  ...
}: {
  environment.systemPackages = with pkgs; [
    efibootmgr

    # Reboot straight into Windows once, without making it the default.
    #
    # efibootmgr -n sets BootNext, which the firmware honours for exactly one
    # boot and then clears by itself. So this is inherently a single shot: the
    # next restart boots Windows, and every restart after that falls back to the
    # normal BootOrder (Linux first). BootOrder is deliberately left untouched.
    (pkgs.writeShellScriptBin "windows-reboot" ''
      set -euo pipefail
      export PATH=${lib.makeBinPath [pkgs.efibootmgr pkgs.gnugrep pkgs.gnused]}:$PATH

      win="$(efibootmgr | grep -i 'Windows Boot Manager' | head -1 \
        | sed -E 's/^Boot([0-9A-Fa-f]{4}).*/\1/')"
      if [ -z "$win" ]; then
        echo "windows-reboot: no 'Windows Boot Manager' UEFI entry found" >&2
        exit 1
      fi

      sudo efibootmgr -n "$win" >/dev/null
      echo "windows-reboot: next boot -> Windows (one-shot); BootOrder unchanged"
      exec systemctl reboot
    '')
  ];

  boot = {
    initrd.systemd.enable = true;

    kernelParams = [
      "iommu=pt"
    ];

    initrd.availableKernelModules = [
      "nvme"
      "ahci"
      "xhci_pci"
      "thunderbolt"
      "usbhid"
      "sd_mod"
    ];

    kernelModules = ["kvm-amd"];

    kernelPackages = pkgs.linuxPackages_zen;

    kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };

    loader = {
      timeout = 30;
      grub = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = true;
        device = "nodev";
        useOSProber = true;
      };
    };
  };
}
