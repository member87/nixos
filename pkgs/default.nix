# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
pkgs: {
  # example = pkgs.callPackage ./example { };
  # neovim = pkgs.callPackage ./nvim { };
  beammp-launcher = pkgs.callPackage ./beammp-launcher.nix {};
  jellyfin-desktop = pkgs.callPackage ./jellyfin-desktop.nix {};
  moonfin = pkgs.callPackage ./moonfin.nix {};
}
