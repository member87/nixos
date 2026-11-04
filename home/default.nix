{
  config,
  outputs,
  stateVersion,
  username,
  ...
}: {
  imports = [
    ./common
  ];

  home = {
    inherit username stateVersion;
    homeDirectory = "/home/${username}";

    sessionPath = [
      "${config.home.homeDirectory}/.local/share/pnpm"
      # `make -C META/zw install` symlinks zw here
      "${config.home.homeDirectory}/bin"
    ];
  };

  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.stable-packages
    ];
    config.allowUnfree = true;
  };
}
