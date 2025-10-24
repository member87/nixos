{
  pkgs,
  inputs,
  ...
}: {
  imports = [inputs.ags.homeManagerModules.default];

  home.packages = with pkgs; [
    astal.hyprland
  ];

  programs.ags = {
    enable = true;

    configDir = ./config;

    extraPackages = with pkgs; [
      inputs.astal.packages.${pkgs.system}.battery
      inputs.astal.packages.${pkgs.system}.hyprland
      inputs.astal.packages.${pkgs.system}.network
      inputs.astal.packages.${pkgs.system}.tray
      inputs.astal.packages.${pkgs.system}.astal4
      inputs.astal.packages.${pkgs.system}.powerprofiles
      inputs.astal.packages.${pkgs.system}.bluetooth
    ];
  };
}
