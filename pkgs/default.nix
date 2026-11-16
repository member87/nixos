# Custom packages, also exposed as flake outputs: `nix build .#<name>`.
pkgs: {
  beamcat = pkgs.callPackage ./beamcat {};
  # result/bin/beamcat.exe, to hand to players on Windows
  beamcat-windows = pkgs.callPackage ./beamcat {forWindows = true;};
  beammp-server = pkgs.callPackage ./beammp-server.nix {};
  jellyfin-desktop = pkgs.callPackage ./jellyfin-desktop.nix {};
  moonfin = pkgs.callPackage ./moonfin.nix {};
  omp-bin = pkgs.callPackage ./omp-bin.nix {};
}
