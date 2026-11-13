{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
  appimageTools,
}: let
  pname = "jellyfin-desktop";
  # A build-linux-appimage run on main. Upstream has no releases, and a branch URL changes
  # under a fixed hash, so pin the run; scripts/nightly-update.sh moves it to the newest one
  # (GitHub drops artifacts after 90 days).
  version = "unstable-2026-11-12";
  runId = "43329422335";

  artifact = fetchurl {
    url = "https://nightly.link/andrewrabert/jellium-desktop/actions/runs/${runId}/linux-appimage-x86_64.zip";
    hash = "sha256-mcRVSJbPXWIR8asCYLmVjg8ylFgzrryVLXVJKaZfODo=";
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

  # Upstream no longer bundles glibc, so the AppImage runs on the FHS env's own.
  appimageContents = appimageTools.extract {
    inherit pname version src;
  };
in
  appimageTools.wrapAppImage {
    inherit pname version;
    src = appimageContents;

    # MangoHud's session-wide Vulkan layer hooks mpv's swapchain and crashes the player
    # (ImGui assert in create_fonts on resize, segfault in NewFrame on present).
    profile = "export DISABLE_MANGOHUD=1";

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
