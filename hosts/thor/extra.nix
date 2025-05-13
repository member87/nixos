# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  inputs,
  hostname,
  pkgs,
  ...
}: {
  systemd.extraConfig = "DefaultTimeoutStopSec=10s";

  nix.settings = {
    substituters = ["https://hyprland.cachix.org"];
    trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
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

  hardware.opengl.enable = true;

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
    unstable.legcord
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
