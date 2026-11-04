# Shared by every host. Roles (common/desktop, gaming.nix, dev.nix) are opted into by each
# host's own default.nix.
{
  flakePath,
  hostname,
  inputs,
  modulesPath,
  outputs,
  stateVersion,
  username,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.home-manager.nixosModules.home-manager
    ./${hostname}
    ./common/core
    ./common/users/${username}
  ];

  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.stable-packages
      inputs.agenix.overlays.default
    ];

    config = {
      allowUnfree = true;
      android_sdk.accept_license = true;
      joypixels.acceptLicense = true;
    };
  };

  # Home Manager runs as part of the system: one build, one switch, one rollback.
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    # A file Home Manager does not own yet is moved aside instead of failing the switch.
    backupFileExtension = "hm-backup";
    extraSpecialArgs = {
      inherit
        inputs
        stateVersion
        hostname
        username
        flakePath
        ;
    };
    users.${username} = ../home;
  };

  system = {
    inherit stateVersion;
  };
}
