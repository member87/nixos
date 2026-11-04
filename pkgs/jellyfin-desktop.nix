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
  version = "unstable-2026-10-19";
  runId = "39185604323";

  artifact = fetchurl {
    url = "https://nightly.link/andrewrabert/jellium-desktop/actions/runs/${runId}/linux-appimage-x86_64.zip";
    hash = "sha256-zkAx/JM6dnA4BAfuQ5jeqosHXg+W7wnu/tZOQjWsATE=";
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

  appimageContents = appimageTools.extract {
    inherit pname version src;
    # The bundled glibc (Fedora, 2.43) cannot load the system Mesa: its
    # libLLVM needs GLIBC_2.44, so dlopen of radv/radeonsi fails and both EGL
    # dmabuf and wgpu paint fall back to wl_shm. Drop glibc so the FHS env's
    # (newer, backward-compatible) one is used. AppRun symlinks the patched
    # ELF interpreter to usr/lib/ld-linux-x86-64.so.2, so point that at the
    # FHS loader.
    postExtract = ''
      cd $out/usr/lib
      chmod u+w .
      rm ld-linux-x86-64.so.2 libBrokenLocale.so* libanl.so* libc.so libc.so.6 \
        libdl.so.2 libm.so libm.so.6 libmvec.so* libnss_compat.so.2 \
        libnss_dns.so.2 libnss_files.so.2 libpcprofile.so libpthread.so.0 \
        libresolv.so* librt.so.1 libthread_db.so* libutil.so.1
      ln -s /lib64/ld-linux-x86-64.so.2 ld-linux-x86-64.so.2
    '';
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
