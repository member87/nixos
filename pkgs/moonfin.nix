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

    extraInstallCommands = ''
      install -Dm0644 ${appimageContents}/moonfin.desktop \
        $out/share/applications/moonfin.desktop
      install -Dm0644 ${appimageContents}/moonfin.png \
        $out/share/icons/hicolor/512x512/apps/moonfin.png

      substituteInPlace $out/share/applications/moonfin.desktop \
        --replace-fail 'Exec=moonfin' 'Exec=${pname}'
    '';

    meta = {
      description = "Enhanced Jellyfin and Emby client";
      homepage = "https://github.com/Moonfin-Client/Moonfin-Core";
      license = lib.licenses.gpl2Only;
      mainProgram = pname;
      platforms = ["x86_64-linux"];
    };
  }
