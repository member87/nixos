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
      pkgs.linuxPackages_zen.v4l2loopback
    ];

    kernelPackages = pkgs.linuxPackages_zen;

    kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };

    loader = {
      grub = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = true;
        useOSProber = true;
        timeout = 30;
      };
    };
  };
}
