{
  inputs,
  pkgs,
  username,
  ...
}: {
  imports = [
    ./boot.nix
    ./hardware.nix
    ./power.nix
    ../common/desktop
    ../common/dev.nix
    ../common/gaming.nix
    inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
  ];

  # nixos-hardware turns panel self-refresh off on every AMD Framework 13
  # for a 2024 hang on the 7040 (drm/amd#3647). PSR lets the display path
  # idle on a static screen; back to true if hangs or flicker return.
  hardware.amdgpu.dcDebugMask.disablePsr = false;

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
