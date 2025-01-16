{ config, pkgs, ... }:

let
  wallpaperUrl = "https://unsplash.com/photos/lFTtQqVfx6g/download?ixid=M3wxMjA3fDB8MXxhbGx8fHx8fHx8fHwxNzM2OTg0ODA4fA&force=true";
  wallpaperFile = pkgs.fetchurl {
    url = wallpaperUrl;
    sha256 = "sha256-PYEm+xn3NJSP8AD/87HaTkAlB+zrEouNg/hoI63ioFs=";
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

