{
  inputs,
  outputs,
  stateVersion,
  username,
  flakePath,
}: {
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
