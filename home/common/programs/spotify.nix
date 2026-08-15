{
  inputs,
  pkgs,
  ...
}: let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in {
  imports = [
    inputs.spicetify-nix.homeManagerModules.spicetify
  ];

  programs.spicetify = {
    enable = true;
    windowManagerPatch = false;
    experimentalFeatures = true;
    alwaysEnableDevTools = true;
    theme = spicePkgs.themes.ziro;
    colorScheme = "rose-pine";
  };
}
