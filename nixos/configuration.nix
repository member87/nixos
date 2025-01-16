# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # You can import other NixOS modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/nixos):
    # outputs.nixosModules.example

    # Or modules from other flakes (such as nixos-hardware):
    # inputs.hardware.nixosModules.common-cpu-amd
    # inputs.hardware.nixosModules.common-ssd

    # You can also split up your configuration and import pieces of it here:
    # ./users.nix

    # Import your generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix
    ./disks.nix
    ./modules
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default
      inputs.agenix.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
  };

  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Opinionated: disable global registry
      flake-registry = "";
      # Workaround for https://github.com/NixOS/nix/issues/9574
      nix-path = config.nix.nixPath;
    };
    # Opinionated: disable channels
    channel.enable = true;

    # Opinionated: make flake registry and nix path match flake inputs
    registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };

  # FIXME: Add the rest of your current configuration

  # TODO: Set your hostname
  networking.hostName = "nixos";
  networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];
  networking.dhcpcd.extraConfig = ''
      nohook resolv.conf
  '';

  users.groups.plugdev = {};

  boot.kernelPackages = pkgs.unstable.linuxPackages_zen;

  systemd.extraConfig = "DefaultTimeoutStopSec=10s";

  services.udev.extraRules = ''
  SUBSYSTEMS=="usb", ATTRS{idVendor}=="2581", ATTRS{idProduct}=="1b7c|2b7c|3b7c|4b7c", TAG+="uaccess", TAG+="udev-acl"
  SUBSYSTEMS=="usb", ATTRS{idVendor}=="2c97", TAG+="uaccess", TAG+="udev-acl"
  KERNEL=="hidraw*", ATTRS{idVendor}=="2c97", MODE="0666"
  '';

  # TODO: Configure your system-wide user settings (groups, etc), add more users as needed.
  users.users = {
    # FIXME: Replace with your username
    jack = {
      # TODO: You can set an initial password for your user.
      # If you do, you can skip setting a root password by passing '--no-root-passwd' to nixos-install.
      # Be sure to change it (using passwd) after rebooting!
      initialPassword = "correcthorsebatterystaple";
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        # TODO: Add your SSH public key(s) here, if you plan on using SSH to connect
      ];
      # TODO: Be sure to add any other groups you need (such as networkmanager, audio, docker, etc)
      extraGroups = ["wheel" "docker" "plugdev"];
      shell = pkgs.zsh;
    };
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.05";

  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;

  time.timeZone = "Europe/London";

  hardware.i2c.enable = true;
  services.hardware.openrgb.enable = true;

  environment.systemPackages = with pkgs; [
    agenix
    brave
    cargo
    curl
    darktable
    ffmpeg
    hyprshot
    hyprpaper
    jellyfin-media-player
    jq
    gcc
    go
    killall
    ledger-live-desktop
    libnotify
    librewolf
    lutris
    lxqt.lxqt-openssh-askpass
    lxqt.lxqt-policykit
    mangohud
    nodejs
    pavucontrol
    playerctl
    python3
    unstable.protontricks
    ripgrep
    socat
    spotify
    unzip
    vesktop
    wineWowPackages.stable
    wl-clipboard
    wget
    wofi
    freerdp3
    inputs.zen-browser.packages."${pkgs.system}".default
    inputs.ghostty.packages."${pkgs.system}".default
    inputs.winapps.packages."${pkgs.system}".winapps-launcher
  ];

  catppuccin.enable = true;
  catppuccin.accent = "pink";

  fileSystems."/run/1TBSSD" = { 
    device = "/dev/disk/by-id/ata-Samsung_SSD_860_EVO_1TB_S3YBNB0K504591D-part1";
    fsType = "ext4";
    options = [ "rw" "data=ordered" "relatime" ];
  };

  virtualisation = {
    docker.enable = true;
  };

  services.spice-vdagentd.enable = true;

  fonts.packages = with pkgs; [
    font-awesome
    (nerdfonts.override {
      fonts = [
        "RobotoMono"
        "FiraCode"
      ];
    })
  ];
}
