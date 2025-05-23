{
  self,
  inputs,
  outputs,
  stateVersion,
  username,
  flakePath,
  ...
}: {
  # Helper function for generating home-manager configs
  mkHome = {
    hostname,
    user ? username,
    system ? "x86_64-linux",
  }:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      extraSpecialArgs = {
        inherit
          self
          inputs
          outputs
          stateVersion
          hostname
          flakePath
          ;
        username = user;
      };
      modules = [
        ../home
      ];
    };

  # Helper function for generating host configs
  mkHost = {
    hostname,
    pkgsInput ? inputs.nixpkgs,
    system ? "x86_64-linux",
  }:
    pkgsInput.lib.nixosSystem {
      specialArgs = {
        inherit
          self
          inputs
          outputs
          stateVersion
          username
          hostname
          flakePath
          system
          ;
      };
      modules = [
        ../hosts
        inputs.agenix.nixosModules.default
      ];
    };

  forAllSystems = inputs.nixpkgs.lib.genAttrs [
    "aarch64-linux"
    "i686-linux"
    "x86_64-linux"
    "aarch64-darwin"
    "x86_64-darwin"
  ];
}
