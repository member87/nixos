{ pkgs, lib, ... }:
{
  environment.systemPackages = with pkgs; [
    efibootmgr
  ];

  boot = {
    initrd.availableKernelModules = [
      "nvme"
      "ahci"
      "xhci_pci"
      "thunderbolt"
      "usbhid"
      "sd_mod"
      "v4l2loopback"
    ];

    kernelModules = [ "kvm-amd" ];

    extraModulePackages = [
      pkgs.unstable.linuxPackages_zen.v4l2loopback
    ];

    kernelPackages = pkgs.unstable.linuxPackages_zen;
  };
}
