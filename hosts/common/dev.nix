# Development: toolchains, the home-ops cluster tools, Docker and nix-ld for unpatched
# binaries.
{pkgs, ...}: {
  # Socket-activated: dockerd starts on the first docker command, not at boot.
  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
  };

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      glibc
      zlib
    ];
  };

  environment.systemPackages = with pkgs; [
    # Nix
    alejandra
    nil

    # Toolchains
    cargo
    gcc
    gnumake
    go
    just
    lua-language-server
    nodejs
    python3
    android-tools

    # home-ops (Talos, Flux, SOPS-encrypted manifests)
    fluxcd
    k9s
    kubectl
    kubeseal
    sops
    talosctl
  ];
}
