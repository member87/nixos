{ config, pkgs, inputs, ... }:

{
  nixpkgs.overlays = [
    (self: super: {
      winapps = inputs.winapps.packages.${pkgs.system}.winapps.overrideAttrs (oldAttrs: {
        patches = oldAttrs.patches ++ [
          ./winapps.patch
        ];
      });
     })
  ];

  environment.systemPackages = with pkgs; [
    winapps
  ];
}
