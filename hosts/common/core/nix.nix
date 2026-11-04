{
  # The flake registry and NIX_PATH come from nixpkgs.flake (set by lib.nixosSystem): only
  # nixpkgs is pinned, so the system closure holds no other flake input's source.
  nix = {
    # Daily store-wide hard-linking; auto-optimise-store would do it during every build.
    optimise.automatic = true;

    settings = {
      warn-dirty = false;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        "@wheel"
      ];
      substituters = [
        "https://nix-community.cachix.org"
        "https://vicinae.cachix.org"
        "https://cache.nixos.org/"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
      ];
    };
  };
}
