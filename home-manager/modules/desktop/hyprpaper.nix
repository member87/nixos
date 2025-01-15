{ config, pkgs, ... }:

let
  wallpaperUrl = "https://github.com/NixOS/nixos-artwork/blob/master/wallpapers/nixos-wallpaper-catppuccin-mocha.png?raw=true";
  wallpaperFile = pkgs.fetchurl {
    url = wallpaperUrl;
    sha256 = "sha256-fmKFYw2gYAYFjOv4lr8IkXPtZfE1+88yKQ4vjEcax1s=";
  };
  hyprpaperSettings = {
    ipc = "on";
    splash = false;
    splash_offset = 2.0;
    preload = [ "${toString wallpaperFile}" ];
    wallpaper = [
      "DP-1,${toString wallpaperFile}"
      "DP-2,${toString wallpaperFile}"
      "HDMI-A-1,${toString wallpaperFile}"
    ];
  };
in

{
  services.hyprpaper = {
    enable = true;

    settings = hyprpaperSettings;
  };
}

