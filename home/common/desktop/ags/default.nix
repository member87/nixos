{
  pkgs,
  inputs,
  ...
}: {
  imports = [inputs.ags.homeManagerModules.default];

  programs.ags = {
    enable = true;

    configDir = ./config;

    extraPackages = with pkgs; [
      inputs.astal.packages.${pkgs.system}.battery
    ];
  };
}
