{
  imports = [
    ./ssh.nix
    ./xserver.nix
    ./hyprland.nix
    ./pipewire.nix
    ./bluetooth.nix
    ./wireguard.nix
    ./tailscale.nix
    ./upower.nix
    ./lockscreen.nix
  ];

  services.flatpak.enable = true;
}
