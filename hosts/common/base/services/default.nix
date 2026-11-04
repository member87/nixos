{
  imports = [
    ./lan-firewall.nix
    ./ssh.nix
    ./hyprland.nix
    ./pipewire.nix
    ./bluetooth.nix
    ./wireguard.nix
    ./tailscale.nix
    ./upower.nix
    ./lockscreen.nix
    ./chromecast.nix
    ./airplay.nix
  ];

  services.flatpak.enable = true;
}
