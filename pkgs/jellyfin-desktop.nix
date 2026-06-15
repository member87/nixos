{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
  appimageTools,
}: let
  pname = "jellyfin-desktop";
  version = "unstable-2026-06-14";

  artifact = fetchurl {
    url = "https://nightly.link/jellyfin/jellyfin-desktop/workflows/build-linux-appimage/main/linux-appimage-x86_64.zip";
    hash = "sha256-FT9DoIBV3dwG3cDS1gG1IAK8vyO2kjnOpQQgOuVZoyU=";
  };

  src = stdenvNoCC.mkDerivation {
    pname = "${pname}-appimage";
    inherit version;

    nativeBuildInputs = [unzip];
    dontUnpack = true;

    installPhase = ''
      runHook preInstall
      unzip ${artifact} -d appimage
      install -Dm0755 appimage/*.AppImage $out
      runHook postInstall
    '';
  };

  appimageContents = appimageTools.extractType2 {inherit pname version src;};
in
  appimageTools.wrapType2 {
    inherit pname version src;

    extraInstallCommands = ''
      install -Dm0644 ${appimageContents}/org.jellyfin.JellyfinDesktop.desktop \
        $out/share/applications/org.jellyfin.JellyfinDesktop.desktop
      install -Dm0644 ${appimageContents}/org.jellyfin.JellyfinDesktop.svg \
        $out/share/icons/hicolor/scalable/apps/org.jellyfin.JellyfinDesktop.svg
    '';

    meta = {
      description = "Jellyfin Desktop Client";
      homepage = "https://github.com/jellyfin/jellyfin-desktop";
      license = lib.licenses.gpl2Only;
      mainProgram = pname;
      platforms = ["x86_64-linux"];
    };
  }
