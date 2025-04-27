# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  inputs,
  hostname,
  pkgs,
  ...
}: {
  systemd.extraConfig = "DefaultTimeoutStopSec=10s";
  services.udev.extraRules = ''
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2581", ATTRS{idProduct}=="1b7c|2b7c|3b7c|4b7c", TAG+="uaccess", TAG+="udev-acl"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2c97", TAG+="uaccess", TAG+="udev-acl"
    KERNEL=="hidraw*", ATTRS{idVendor}=="2c97", MODE="0666"
  '';

  nix.settings = {
    substituters = ["https://hyprland.cachix.org"];
    trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
  };

  fileSystems."/run/1TBSSD" = {
    device = "/dev/disk/by-id/ata-Samsung_SSD_860_EVO_1TB_S3YBNB0K504591D-part1";
    fsType = "ext4";
    options = [
      "rw"
      "data=ordered"
      "relatime"
    ];
  };

  programs.thunar.enable = true;

  hardware.i2c.enable = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;

    extraPackages = [
      pkgs.amdvlk
    ];
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
    ledger-live-desktop
    libnotify
    librewolf
    localstack
    lutris
    lxqt.lxqt-openssh-askpass
    lxqt.lxqt-policykit
    mangohud
    unstable.neovim
    nodejs
    nil
    nixfmt-rfc-style
    obsidian
    pavucontrol
    playerctl
    python3
    unstable.protontricks
    obs-studio
    unstable.rose-pine-hyprcursor
    r2modman
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

  services.greetd = {
    enable = true;

    settings = {
      default_session = {
        command = ''            
          ${pkgs.greetd.tuigreet}/bin/tuigreet \
            --remember \
            --remember-session \
            --asterisks \
            --time '';
        user = "greeter";
      };
    };
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
