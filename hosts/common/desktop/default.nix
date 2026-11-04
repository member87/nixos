# Graphical workstation: Hyprland behind the quickshell greeter, audio, Bluetooth,
# casting and the desktop apps.
{pkgs, ...}: {
  imports = [
    ./airplay.nix
    ./bluetooth.nix
    ./chromecast.nix
    ./greeter.nix
    ./hyprland.nix
    ./lockscreen.nix
    ./pipewire.nix
    ./upower.nix
  ];

  boot = {
    consoleLogLevel = 0;
    kernelParams = [
      "quiet"
      "udev.log_level=3"
      "systemd.show_status=auto"
    ];
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  fonts.packages = with pkgs; [
    font-awesome
    monaspace
    nerd-fonts.roboto-mono
    nerd-fonts.fira-code
  ];

  programs.thunar.enable = true;
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  services.flatpak.enable = true;
  services.spice-vdagentd.enable = true;

  programs.kdeconnect.enable = true;
  programs.localsend = {
    enable = true;
    # The module opens 53317 on every interface by default; lan-firewall.nix scopes it.
    openFirewall = false;
  };
  networking.firewall.lan = {
    allowedTCPPorts = [53317];
    allowedUDPPorts = [53317];
  };

  # Ledger hardware wallets, for ledger-live-desktop. uaccess hands the device to the
  # logged-in seat user only; Ledger's own rules make the hidraw node world-writable.
  services.udev.extraRules = ''
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2581", ATTRS{idProduct}=="1b7c|2b7c|3b7c|4b7c", TAG+="uaccess", TAG+="udev-acl"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2c97", TAG+="uaccess", TAG+="udev-acl"
    KERNEL=="hidraw*", ATTRS{idVendor}=="2c97", MODE="0660", TAG+="uaccess"
  '';

  environment.systemPackages = with pkgs; [
    bibata-cursors
    bluetui
    brave
    darktable
    ffmpeg
    ghostty
    google-chrome
    gphoto2
    hyprshot
    jellyfin-desktop
    ledger-live-desktop
    libnotify
    lxqt.lxqt-openssh-askpass
    moonfin
    nwg-displays
    obs-studio
    obsidian
    pavucontrol
    playerctl
    proton-pass
    proton-vpn
    satty
    stable.freecad
    wl-clipboard
  ];
}
