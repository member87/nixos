{pkgs, ...}: let
  wallpaperUrl = "https://cdn.lab.jackhumes.com/background.jpg";
  wallpaperFile = pkgs.fetchurl {
    url = wallpaperUrl;
    sha256 = "sha256-4/VPKyrnF9rm60p3k7e4F3Ze0pnHIgoKVAAzLi6flVs=";
  };
in {
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = false;
      splash_offset = 2;

      wallpaper = [
        {
          monitor = "DP-1";
          path = "${wallpaperFile}";
        }
        {
          monitor = "DP-2";
          path = "${wallpaperFile}";
        }
        {
          monitor = "HDMI-A-1";
          path = "${wallpaperFile}";
        }
        {
          monitor = "eDP-1";
          path = "${wallpaperFile}";
        }
      ];
    };
  };
}
