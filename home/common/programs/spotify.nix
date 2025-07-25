{
  inputs,
  pkgs,
  ...
}: let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.system};
in {
  imports = [
    inputs.spicetify-nix.homeManagerModules.spicetify
  ];

  programs.spicetify = {
    enable = true;
    enabledExtensions = [
      {
        src = pkgs.fetchFromGitHub {
          owner = "Spikerko";
          repo = "spicy-lyrics";
          rev = "5.2.0";
          hash = "sha256-LuuHtk3ebkPLnbc9qtKm/iN5B2WrtVwNDuRhENLHspM=";
        };
        name = "builds/spicy-lyrics.mjs";
      }
    ];
    windowManagerPatch = false;
    experimentalFeatures = true;
    alwaysEnableDevTools = true;
    #theme = spicePkgs.themes.catppuccin;
    #colorScheme = "mocha";
  };
}
