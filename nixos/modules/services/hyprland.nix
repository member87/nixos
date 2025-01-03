{ pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    portalPackage = pkgs.unstable.xdg-desktop-portal-hyprland;
  };
}

