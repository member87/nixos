{
  pkgs,
  lib,
  ...
}: {
  environment.systemPackages = with pkgs; [
    efibootmgr
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
