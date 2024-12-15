{ config, pkgs, inputs, ... }:

{
  boot.kernel.sysctl = {
    "vm.max_map_count" = 16777216;
    "fs.file-max" = 524288;
  };

  zramSwap = {
    enable = true;
    memoryMax = 32 * 1024 * 1024 * 1024;  # 32 GB ZRAM
  };

  environment.systemPackages = with pkgs; [
    unstable.gamescope
    (inputs.nix-gaming.packages.${pkgs.system}.star-citizen.override {
      location = "/run/1TBSSD/star-citizen";
      wine = pkgs.unstable.wine64;
    })
  ];
}
