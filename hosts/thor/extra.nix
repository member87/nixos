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

  # systemd.extraConfig = "DefaultTimeoutStopSec=10s";

  nix.settings = {
    substituters = ["https://hyprland.cachix.org"];
    trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
  };

  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  environment.variables = {
    PNPM_HOME = "/home/jack/.local/share/pnpm";
    AQ_DRM_DEVICES = "/dev/dri/card1";
    GDK_SCALE = 2;
  };

  networking.networkmanager.enable = true;

  programs.thunar.enable = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;

    package = pkgs.mesa;
  };

  environment.systemPackages = with pkgs; [
    ghostty
    alacritty
    gh
    vlc
    cheese
    pnpm
    wireguard-tools
    protonvpn-gui
    swayosd
    brightnessctl
    playerctl
    alejandra
    agenix
    amdvlk
    bat
    brave
    cargo
    curl
    # darktable
    ffmpeg
    fprintd
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
    neovim
    nodejs
    nil
    nixfmt-rfc-style
    obsidian
    pavucontrol
    playerctl
    python3
    protontricks
    obs-studio
    rose-pine-hyprcursor
    r2modman
    ripgrep
    socat
    treefmt
    unzip
    legcord
    wineWowPackages.stable
    wl-clipboard
    wget
    freerdp3
    inputs.zen-browser.packages."${pkgs.system}".beta
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
    nerd-fonts.roboto-mono
    nerd-fonts.fira-code
  ];
}
