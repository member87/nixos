{
  lib,
  fetchurl,
  appimageTools,
}: let
  pname = "moonfin";
  version = "2.1.0";

  src = fetchurl {
    url = "https://github.com/Moonfin-Client/Moonfin-Core/releases/download/${version}/Moonfin_Linux_v${version}.AppImage";
    hash = "sha256-kMvxA6MfTJv9TM/g790oGWQjrlHGI+DMgFpYVhjfb8Q=";
  };

  appimageContents = appimageTools.extractType2 {inherit pname version src;};
in
  appimageTools.wrapType2 {
    inherit pname version src;

    extraPkgs = pkgs: [
      pkgs.harfbuzzFull
      pkgs.libepoxy
      pkgs.libxv
    ];

    extraInstallCommands = ''
      install -Dm0644 ${appimageContents}/org.moonfin.linux.png \
        $out/share/icons/hicolor/512x512/apps/org.moonfin.linux.png

      install -Dm0644 /dev/stdin $out/share/applications/org.moonfin.linux.desktop <<EOF
      [Desktop Entry]
      Type=Application
      Name=Moonfin
      Comment=Jellyfin and Emby media client
      Exec=$out/bin/${pname} %U
      Icon=org.moonfin.linux
      Terminal=false
      Categories=AudioVideo;Video;Player;TV;
      Keywords=Jellyfin;Emby;Media;Video;TV;
      StartupWMClass=org.moonfin.linux
      EOF
    '';

    meta = {
      description = "Enhanced Jellyfin and Emby client";
      homepage = "https://github.com/Moonfin-Client/Moonfin-Core";
      license = lib.licenses.gpl2Only;
      mainProgram = pname;
      platforms = ["x86_64-linux"];
    };
  }
