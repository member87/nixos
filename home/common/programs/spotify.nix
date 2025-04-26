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
      beautifulLyrics
    ];
    alwaysEnableDevTools = true;
    theme = spicePkgs.themes.catppuccin;
    colorScheme = "mocha";
    spotifyPackage = pkgs.unstable.spotify;
    spicetifyPackage = pkgs.unstable.spicetify-cli;
  };
}
