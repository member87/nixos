{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ./boot.nix
    ./hardware.nix
    ./vfio.nix
    ../common/desktop
    ../common/dev.nix
    ../common/gaming.nix
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

  # Virtual FIDO2/U2F device for WebAuthn
  services.udev.extraRules = ''
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
  services.hardware.openrgb.enable = true;

  environment.systemPackages = with pkgs; [
    gamescope
    libfido2 # Provides virtual authenticator tools
    tor-browser
    openra
    prismlauncher
  ];
}
