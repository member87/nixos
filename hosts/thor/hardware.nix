{
  config,
  lib,
  ...
}: {
  imports = [./disks.nix];

  swapDevices = [
    {
      device = "/swapfile";
      size = 16 * 1024;
    }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
