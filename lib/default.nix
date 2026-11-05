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
        # the commit the system was built from (`nixos-version --json`; the bar's update
        # check compares it with main), "<rev>-dirty" from a checkout with changes
        {system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;}
      ];
    };

  # Every package in pkgs/ is x86_64-linux only.
  forAllSystems = inputs.nixpkgs.lib.genAttrs ["x86_64-linux"];
}
