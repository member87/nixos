# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  inputs,
  hostname,
  pkgs,
  ...
}: {
  networking.hostName = hostname;
  networking.nameservers = [
    "1.1.1.1"
    "1.0.0.1"
  ];
  networking.dhcpcd.extraConfig = ''
    nohook resolv.conf
  '';

  users.groups.plugdev = {};

  systemd.extraConfig = "DefaultTimeoutStopSec=10s";
  services.udev.extraRules = ''
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2581", ATTRS{idProduct}=="1b7c|2b7c|3b7c|4b7c", TAG+="uaccess", TAG+="udev-acl"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2c97", TAG+="uaccess", TAG+="udev-acl"
    KERNEL=="hidraw*", ATTRS{idVendor}=="2c97", MODE="0666"
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

  hardware.i2c.enable = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  services.hardware.openrgb.enable = true;
  environment.systemPackages = with pkgs; [
    alejandra
    agenix
    amdvlk
    bat
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
    gnumake
    gphoto2
    killall
    lua-language-server
    lazygit
    ledger-live-desktop
    libnotify
    librewolf
    localstack
    lutris
    lxqt.lxqt-openssh-askpass
    lxqt.lxqt-policykit
    mangohud
    neovim
    nodejs
    nil
    nixfmt-rfc-style
    obsidian
    pavucontrol
    playerctl
    python3
    unstable.protontricks
    obs-studio
    ripgrep
    socat
    treefmt
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

  programs.nix-ld.enable = true;

  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    glibc
    zlib
  ];

  virtualisation = {
    docker.enable = true;
  };

  services.spice-vdagentd.enable = true;

  fonts.packages = with pkgs; [
    font-awesome
    monaspace
    (nerdfonts.override {
      fonts = [
        "RobotoMono"
        "FiraCode"
      ];
    })
  ];
}
