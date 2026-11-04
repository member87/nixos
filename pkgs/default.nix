# Custom packages, also exposed as flake outputs: `nix build .#<name>`.
pkgs: {
  jellyfin-desktop = pkgs.callPackage ./jellyfin-desktop.nix {};
  moonfin = pkgs.callPackage ./moonfin.nix {};
  omp-bin = pkgs.callPackage ./omp-bin.nix {};
}
