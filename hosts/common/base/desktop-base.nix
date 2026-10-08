{
  inputs,
  pkgs,
  config,
  ...
}: {
  nix.settings = {
    substituters = [
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
      "https://cache.nixos.org/"
    ];
    trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  networking.wireless.iwd.enable = true;
  # iwd's own autoconnect races NetworkManager and blacklists networks with
  # an exponential backoff after a single failed association (e.g. mt7925e
  # flakiness after resume), leaving the machine offline for minutes. Hand
  # autoconnect to NetworkManager; impala still works (explicit connects).
  networking.wireless.iwd.settings.General.AutoConnect = false;
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd";
  # NM only uses its own autoconnect with the iwd backend if this is unset/
  # false; otherwise iwd's blacklist logic decides everything.
  environment.etc."NetworkManager/conf.d/wifi-iwd-autoconnect.conf".text = ''
    [device]
    wifi.iwd.autoconnect=false
  '';

  boot = {
    consoleLogLevel = 0;
    kernelParams = [
      "quiet"
      "udev.log_level=3"
      "systemd.show_status=auto"
    ];
  };

  programs.thunar.enable = true;

  services.udisks2.enable = true;
  services.gvfs.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

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
        command = "${pkgs.tuigreet}/bin/tuigreet --remember --remember-session --asterisks --time --sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions --xsessions ${config.services.displayManager.sessionData.desktops}/share/xsessions";
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
