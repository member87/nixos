{inputs, ...}: {
  # Custom packages from pkgs/.
  additions = final: _prev: import ../pkgs final.pkgs;

  # nixpkgs-stable, reachable as pkgs.stable.
  stable-packages = final: _prev: {
    stable = import inputs.nixpkgs-stable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };
}
