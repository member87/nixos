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
    enabledExtensions = with spicePkgs.extensions; [
      shuffle
      # beautifulLyrics
      {
        src = pkgs.fetchFromGitHub {
          owner = "Spikerko";
          repo = "spicy-lyrics";
          rev = "5.0.1";
          hash = "sha256-34r17QcqIEO9FbeywfyyEi8qwY0tBoSAv/BpYV7OQFw=";
        };
        name = "builds/spicy-lyrics.mjs";
      }
    ];
    alwaysEnableDevTools = true;
    theme = spicePkgs.themes.catppuccin;
    colorScheme = "mocha";
  };
}
