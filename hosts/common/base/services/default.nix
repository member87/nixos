{
  imports = [
    ./ssh.nix
    ./xserver.nix
    ./hyprland.nix
    ./pipewire.nix
    ./wireguard.nix
    ./tailscale.nix
  ];

  services.flatpak.enable = true;
}
