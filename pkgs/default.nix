# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
pkgs: {
  # example = pkgs.callPackage ./example { };
  # neovim = pkgs.callPackage ./nvim { };
  beammp-launcher = pkgs.callPackage ./beammp-launcher.nix {};
  jellyfin-desktop = pkgs.callPackage ./jellyfin-desktop.nix {};
  moonfin = pkgs.callPackage ./moonfin.nix {};
  # On nixpkgs-stable: the source patch rebuilds QEMU, and stable's QEMU changes a few times
  # a month instead of on every nixos-unstable bump.
  qemu-stealth = pkgs.callPackage ./qemu-stealth.nix {inherit (pkgs.stable) qemu_kvm;};
  omp-bin = pkgs.callPackage ./omp-bin.nix {};
}
