# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  inputs,
  hostname,
  pkgs,
  ...
}: {
  imports = [
    inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
  ];

  services.printing.enable = true;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  security.pam.services.hyprlock = {};

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  environment.variables = {
    PNPM_HOME = "/home/jack/.local/share/pnpm";
    AQ_DRM_DEVICES = "/dev/dri/card1";
    GDK_SCALE = 2;
  };

  hardware.graphics.package = pkgs.mesa;

  environment.systemPackages = with pkgs; [
    alacritty
    gh
    vlc
    cheese
    pnpm
    wireguard-tools
    protonvpn-gui
    swayosd
    brightnessctl
    amdvlk
    fprintd
  ];
}
