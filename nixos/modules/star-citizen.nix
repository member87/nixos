{ config, pkgs, inputs, ... }:

let 
  onnxRuntimePath = pkgs.onnxruntime.outPath;
in {
  boot.kernel.sysctl = {
    "vm.max_map_count" = 16777216;
    "fs.file-max" = 524288;
  };

  zramSwap = {
    enable = true;
    memoryMax = 32 * 1024 * 1024 * 1024;  # 32 GB ZRAM
  };

  nixpkgs.overlays = [
    (self: super: {
      opentrack = super.opentrack.overrideAttrs (oldAttrs: {
        cmakeFlags = oldAttrs.cmakeFlags ++ [
          "-DONNXRuntime_DIR=${onnxRuntimePath}"
        ];

        buildInputs = oldAttrs.buildInputs ++ [
          pkgs.onnxruntime
        ];
      });


      star-citizen = inputs.nix-gaming.packages.${pkgs.system}.star-citizen.overrideAttrs (oldAttrs: {
        script = ''
        echo "test"
        '';
      });
     })
  ];

  environment.systemPackages = with pkgs; [
    opentrack
    unstable.gamescope
    unstable.wine64
    (star-citizen.override {
      location = "/run/1TBSSD/star-citizen";
      wine = pkgs.unstable.wine64;
    })
  ];
}
