{
  imports = [
    ./ssh.nix
    ./xserver.nix
    ./hyprland.nix
    ./pipewire.nix
    ./wireguard.nix
  ];

  services.flatpak.enable = true;
}
