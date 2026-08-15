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
    url = "https://nightly.link/andrewrabert/jellium-desktop/workflows/build-linux-appimage/main/linux-appimage-x86_64.zip";
    hash = "sha256-J3XJIQ5wP5eq+bo+y+0fJ74i2LnrVcYPAEiFJiIKozs=";
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

  appimageContents = appimageTools.extract {inherit pname version src;};
in
  appimageTools.wrapType2 {
    inherit pname version src;

    extraInstallCommands = ''
      install -Dm0644 ${appimageContents}/net.nullsum.JelliumDesktop.desktop \
        $out/share/applications/net.nullsum.JelliumDesktop.desktop
      install -Dm0644 ${appimageContents}/net.nullsum.JelliumDesktop.svg \
        $out/share/icons/hicolor/scalable/apps/net.nullsum.JelliumDesktop.svg
      substituteInPlace $out/share/applications/net.nullsum.JelliumDesktop.desktop \
        --replace-fail "Exec=jellium-desktop" "Exec=${pname}"
    '';

    meta = {
      description = "Jellyfin Desktop Client";
      homepage = "https://github.com/jellyfin/jellyfin-desktop";
      license = lib.licenses.gpl2Only;
      mainProgram = pname;
      platforms = ["x86_64-linux"];
    };
  }
