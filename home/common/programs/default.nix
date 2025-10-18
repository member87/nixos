{pkgs, ...}: {
  imports = [
    ./simple.nix
    ./zsh.nix
    ./starship.nix
    ./spotify.nix
    ./swaync.nix
    ./git.nix
    ./winapps.nix
    ./nvim.nix
    ./btop.nix
    ./lazygit.nix
    ./zellij.nix
    ./battery-notify.nix
  ];

  home.packages = with pkgs; [
    beammp-launcher
  ];
}
