{
  inputs,
  outputs,
  stateVersion,
  username,
  flakePath,
}: {
  mkHome = {
    hostname,
    user ? username,
    system ? "x86_64-linux",
  }:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      extraSpecialArgs = {
        inherit
          inputs
          outputs
          stateVersion
          hostname
          flakePath
          ;
        username = user;
      };
      modules = [../home];
    };

  mkHost = {hostname}:
    inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit
          inputs
          outputs
          stateVersion
          username
          hostname
          flakePath
          ;
      };
      modules = [
        ../hosts
        inputs.agenix.nixosModules.default
        inputs.disko.nixosModules.disko
      ];
    };

  # Every package in pkgs/ is x86_64-linux only.
  forAllSystems = inputs.nixpkgs.lib.genAttrs ["x86_64-linux"];
}
