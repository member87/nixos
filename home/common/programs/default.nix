{pkgs, ...}: {
  imports = [
    ./simple.nix
    ./zsh.nix
    ./starship.nix
    ./spotify.nix
    ./dunst.nix
    ./git.nix
    ./winapps.nix
    ./nvim.nix
    ./btop.nix
    ./lazygit.nix
    ./zellij.nix
  ];

  home.packages = with pkgs; [
    beammp-launcher
  ];
}
