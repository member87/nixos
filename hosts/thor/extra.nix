{
  inputs,
  pkgs,
  username,
  ...
}: {
  imports = [
    inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
    ./power.nix
  ];

  services.printing.enable = true;

  hardware.fw-fanctrl = {
    enable = true;
    config = {
      defaultStrategy = "laziest";
    };
    disableBatteryTempCheck = false;
  };

  environment.variables = {
    PNPM_HOME = "/home/${username}/.local/share/pnpm";
    AQ_DRM_DEVICES = "/dev/dri/card1";
    GDK_SCALE = 2;
  };

  networking.nameservers = [
    "10.0.0.201"
    "9.9.9.9"
  ];

  environment.systemPackages = with pkgs; [
    alacritty
    gh
    vlc
    cheese
    pnpm
    wireguard-tools
    openrazer-daemon
    polychromatic
  ];

  hardware.openrazer.enable = true;
}
