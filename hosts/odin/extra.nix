# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  inputs,
  hostname,
  pkgs,
  ...
}: {
  imports = [
    ./vfio.nix
    inputs.nix-citizen.nixosModules.default
  ];

  # nix-citizen and nix-gaming cachix (Star Citizen's wine, dxvk, vkd3d-proton)
  nix.settings = {
    extra-substituters = [
      "https://nix-citizen.cachix.org"
      "https://nix-gaming.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-citizen.cachix.org-1:lPMkWc2X8XD4/7YPEEwXKKBg+SVbYTVrAaLA2wQTKCo="
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
    ];
  };

  programs.rsi-launcher = {
    enable = true;
    location = "/run/1TBSSD/star-citizen";
    # Use nix-citizen's own packages (cached on nix-citizen.cachix.org). Its overlay rebuilds
    # wine-astral against our nixpkgs and changes enough of it that Hyprland and xwayland
    # are rebuilt too.
    includeOverlay = false;
  };

  services.udev.extraRules = ''
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2581", ATTRS{idProduct}=="1b7c|2b7c|3b7c|4b7c", TAG+="uaccess", TAG+="udev-acl"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2c97", TAG+="uaccess", TAG+="udev-acl"
    KERNEL=="hidraw*", ATTRS{idVendor}=="2c97", MODE="0666"

    # Virtual FIDO2/U2F device for WebAuthn
    KERNEL=="uhid", SUBSYSTEM=="misc", MODE="0660", TAG+="uaccess"
  '';

  fileSystems."/run/1TBSSD" = {
    device = "/dev/disk/by-id/ata-Samsung_SSD_860_EVO_1TB_S3YBNB0K504591D-part1";
    fsType = "ext4";
    options = [
      "rw"
      "data=ordered"
      "relatime"
    ];
  };

  networking.nameservers = [
    "10.0.0.201"
  ];

  hardware.i2c.enable = true;
  hardware.graphics.enable = true;
  services.hardware.openrgb.enable = true;

  environment.systemPackages = with pkgs; [
    talosctl
    kubectl
    gamescope
    stable.darktable
    libfido2 # Provides virtual authenticator tools
    tor-browser
    openra
    prismlauncher
    r2modman
  ];
}
