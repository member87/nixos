{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    efibootmgr
  ];

  boot.isContainer = true;

  systemd.mounts = [
    {
      where = "/sys/kernel/debug";
      enable = false;
    }
  ];

  boot = {
    initrd.systemd.enable = true;
    initrd.availableKernelModules = [
      "nvme"
      "ahci"
      "xhci_pci"
      "thunderbolt"
      "usbhid"
      "sd_mod"
      "v4l2loopback"
    ];

    kernelModules = ["kvm-amd"];

    extraModulePackages = [
      pkgs.unstable.linuxPackages_zen.v4l2loopback
    ];

    kernelPackages = pkgs.unstable.linuxPackages_zen;

    kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };

    loader = {
      grub = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = true;
      };
    };
  };
}
