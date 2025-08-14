{
  outputs,
  stateVersion,
  username,
  inputs,
  ...
}: {
  imports = [
    ./common
  ];

  home = {
    inherit username stateVersion;
    homeDirectory = "/home/${username}";

    sessionPath = [
      "/home/jack/.local/share/pnpm"
    ];
  };

  programs.firefox.enable = true;

  nixpkgs = {
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.stable-packages

      # You can also add overlays exported from other flakes:
      inputs.agenix.overlays.default
    ];

    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
      # permittedInsecurePackages = [ "electron-25.9.0" ];
    };
  };
}
