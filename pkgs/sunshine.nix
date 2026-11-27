# Sunshine from its new home, SunshineStream/Sunshine, adapted from the nixpkgs
# package (pkgs/by-name/su/sunshine), which still tracks LizardByte/Sunshine.
# Linux only, without CUDA.
{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchzip,
  autoPatchelfHook,
  makeWrapper,
  buildNpmPackage,
  cmake,
  avahi,
  libevdev,
  libpulseaudio,
  libxtst,
  libxrandr,
  libxi,
  libxfixes,
  libxdmcp,
  libx11,
  libxcb,
  openssl,
  libopus,
  boost,
  pkg-config,
  libdrm,
  wayland,
  wayland-scanner,
  wayland-protocols,
  libffi,
  libcap,
  libgbm,
  curl,
  pcre2,
  python3,
  libuuid,
  libselinux,
  libsepol,
  libthai,
  libdatrie,
  libxkbcommon,
  libepoxy,
  libva,
  libvdpau,
  libglvnd,
  numactl,
  amf-headers,
  svt-av1,
  shaderc,
  vulkan-loader,
  qt6,
  libnotify,
  pipewire,
  miniupnpc,
  nlohmann_json,
  coreutils,
  udevCheckHook,
}: let
  version = "2026.1127.15710";

  # Upstream's cmake fetches a pre-built ffmpeg from LizardByte/build-deps at
  # configure time, which the sandbox cannot do, so it is fetched here and
  # passed in via FFMPEG_PREPARED_BINARIES. The tag must match BUILD_DEPS_TAG
  # in the release's package-lock.cmake. The bundle also ships the NV codec
  # and Vulkan headers, so the build_deps git repository is never needed.
  buildDepsTag = "v2026.1017.131201";
  ffmpegPrebuilt = fetchzip {
    url = "https://github.com/LizardByte/build-deps/releases/download/${buildDepsTag}/Linux-x86_64-ffmpeg.tar.gz";
    hash = "sha256-ZFtxcQvlC8k4Nv3HOV5CVhV1F8Yz0McJ98oQ6Gs2slU=";
  };

  # The remaining third-party sources are CPM packages that cmake would clone
  # at configure time. Each one is pinned to the tag or commit in the release's
  # package-lock.cmake and handed to CPM through CPM_<name>_SOURCE, which makes
  # it use the directory instead of downloading. Boost, nlohmann_json and
  # wayland-protocols come from nixpkgs instead, and the Windows/macOS-only
  # packages (nvapi, ViGEmClient, TPCircularBuffer) are never requested.
  cpmSources = {
    glad = fetchFromGitHub {
      owner = "Dav1dde";
      repo = "glad";
      tag = "v2.0.8";
      hash = "sha256-aWqqOtNbaWMIKN1KAnXfTbDOgcZ87XaXwVGVgePzLDE=";
    };
    libdisplaydevice = fetchFromGitHub {
      owner = "LizardByte";
      repo = "libdisplaydevice";
      tag = "v2026.1008.124543";
      hash = "sha256-uiJ/IoVKcu7RR+p1IPOXBykpLMKoyZ+bMCLH0EHuGjw=";
    };
    # Its lizardbyte-common submodule is only built for Windows or tests.
    libvirtualhid = fetchFromGitHub {
      owner = "LizardByte";
      repo = "libvirtualhid";
      rev = "dd8153df338c6fb399ea4a048fa97b4c536f12a0";
      hash = "sha256-Ea8JvcezyUd/K0qP3nVBOYUH5MfOCEsTtTm1y3Iw1u0=";
    };
    # Sunshine builds ENet from the enet submodule and uses nanors for FEC.
    moonlight-common-c = fetchFromGitHub {
      owner = "moonlight-stream";
      repo = "moonlight-common-c";
      rev = "b4ee1cea3d19e13c0b37c26585e6b1ee174effcb";
      hash = "sha256-l4UMlfY523DhcuMDOHnYVYLRs2PxPrj7J2fiMveGvXk=";
      fetchSubmodules = true;
    };
    plasma_wayland_protocols = fetchFromGitHub {
      owner = "KDE";
      repo = "plasma-wayland-protocols";
      tag = "v1.23.0";
      hash = "sha256-2Eqt0+24NEZSk3lEtvpkN5RGZ86EKi7/o4qovXk1hTw=";
    };
    simple_web_server = fetchFromGitHub {
      owner = "LizardByte-infrastructure";
      repo = "Simple-Web-Server";
      rev = "546895a93a29062bb178367b46c7afb72da9881e";
      hash = "sha256-sIuZUqpK8eiPs1wIlE8hJgtynEoYpLxMaWxQGviifME=";
    };
    tray = fetchFromGitHub {
      owner = "LizardByte";
      repo = "tray";
      tag = "v2026.1117.200659";
      hash = "sha256-BOIzv/dKYoMqMJoWAPSy98Dmq27V8oudMeviHCTf+DQ=";
    };
    wlr_protocols = fetchFromGitHub {
      owner = "LizardByte-infrastructure";
      repo = "wlr-protocols";
      rev = "1106a4a1c57562ddd438c547da4c0d6dc150d624";
      hash = "sha256-xM+VjQ0ngYm3NLhAGKY6qrm2FFngUvpVe5Q0FudgD4g=";
    };
  };
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "sunshine";
    inherit version;

    __structuredAttrs = true;
    strictDeps = true;

    # Only third-party/lizardbyte-common is built; the other submodules (docs
    # tooling, flatpak) come along because fetchSubmodules fetches them all.
    src = fetchFromGitHub {
      owner = "SunshineStream";
      repo = "Sunshine";
      tag = "v${finalAttrs.version}";
      hash = "sha256-jvr1ULNj/Vi1CDkTNqRCjnZeFJNiVHI8srCtBd7yLv4=";
      fetchSubmodules = true;
    };

    # The web UI is a vite app that cmake would build with npm during the
    # build; build it here instead and drop its output where cmake installs it
    # from (see preBuild).
    ui = buildNpmPackage {
      inherit (finalAttrs) src version;
      pname = "sunshine-ui";
      npmDepsHash = "sha256-RO9VtNC++Sj/4zaBnd8c2G1ii2Ai1PbpnEl4S9lJUCE=";

      installPhase = ''
        runHook preInstall

        cp -r build/assets/web "$out"

        runHook postInstall
      '';
    };

    # Don't look for npm, since the web UI is built separately.
    postPatch =
      ''
        substituteInPlace cmake/targets/common.cmake \
          --replace-fail 'find_program(NPM npm REQUIRED)' ""
      ''
      # Systemd and udev aren't build inputs; their install directories are
      # set in cmakeFlags instead.
      + ''
        substituteInPlace cmake/packaging/linux.cmake \
          --replace-fail 'find_package(Systemd)' "" \
          --replace-fail 'find_package(Udev)' ""
      ''
      # The remaining @VAR@ placeholders are substituted by cmake's
      # configure_file(... @ONLY) during the build.
      + ''
        substituteInPlace packaging/linux/dev.lizardbyte.app.Sunshine.desktop \
          --replace-fail '/usr/bin/env systemctl start --u app-@PROJECT_FQDN@' 'sunshine'

        substituteInPlace packaging/linux/app-dev.lizardbyte.app.Sunshine.service.in \
          --replace-fail '/bin/sleep' '${lib.getExe' coreutils "sleep"}'
      '';

    nativeBuildInputs = [
      cmake
      pkg-config
      # glad's generator needs Jinja2 at configure time; GLAD_SKIP_PIP_INSTALL
      # stops cmake from trying to install it with uv.
      (python3.withPackages (ps: [ps.jinja2]))
      makeWrapper
      qt6.wrapQtAppsHook
      wayland-scanner
      # glslc compiles the Vulkan encoder's shader during the build.
      shaderc
      # Avoid fighting upstream's usage of vendored ffmpeg libraries.
      autoPatchelfHook
    ];

    buildInputs = [
      boost
      curl
      miniupnpc
      nlohmann_json
      openssl
      libopus
      qt6.qtbase
      qt6.qtsvg
      avahi
      libevdev
      libpulseaudio
      libx11
      libxcb
      libxfixes
      libxrandr
      libxtst
      libxi
      libdrm
      wayland
      wayland-protocols
      libffi
      libcap
      pcre2
      libuuid
      libselinux
      libsepol
      libthai
      libdatrie
      libxdmcp
      libxkbcommon
      libepoxy
      libva
      libvdpau
      numactl
      libgbm
      amf-headers
      svt-av1
      vulkan-loader
      pipewire
      libnotify
    ];

    runtimeDependencies = [
      avahi
      libgbm
      libxrandr
      libxcb
      libglvnd
    ];

    cmakeFlags =
      [
        "-Wno-dev"
        (lib.cmakeBool "BOOST_USE_STATIC" false)
        (lib.cmakeBool "BUILD_DOCS" false)
        (lib.cmakeBool "BUILD_TESTS" false)
        (lib.cmakeFeature "SUNSHINE_PUBLISHER_NAME" "nixpkgs")
        (lib.cmakeFeature "SUNSHINE_PUBLISHER_WEBSITE" "https://nixos.org")
        (lib.cmakeFeature "SUNSHINE_PUBLISHER_ISSUE_URL" "https://github.com/NixOS/nixpkgs/issues")
        (lib.cmakeFeature "FFMPEG_PREPARED_BINARIES" "${ffmpegPrebuilt}")
        (lib.cmakeBool "GLAD_SKIP_PIP_INSTALL" true)
        (lib.cmakeBool "SUNSHINE_SYSTEM_WAYLAND_PROTOCOLS" true)
        (lib.cmakeBool "SUNSHINE_ENABLE_CUDA" false)
        # Upstream asks systemd and udev's pkg-config for these FHS directories.
        (lib.cmakeBool "UDEV_FOUND" true)
        (lib.cmakeBool "SYSTEMD_FOUND" true)
        (lib.cmakeFeature "UDEV_RULES_INSTALL_DIR" "lib/udev/rules.d")
        (lib.cmakeFeature "SYSTEMD_USER_UNIT_INSTALL_DIR" "lib/systemd/user")
        (lib.cmakeFeature "SYSTEMD_MODULES_LOAD_DIR" "lib/modules-load.d")
        # Used in the generated systemd unit's ExecStart= line.
        (lib.cmakeFeature "SUNSHINE_EXECUTABLE_PATH" "${placeholder "out"}/bin/sunshine")
      ]
      ++ lib.mapAttrsToList (name: src: lib.cmakeFeature "CPM_${name}_SOURCE" "${src}") cpmSources;

    env = {
      # Needed to trigger CMake version configuration.
      BUILD_VERSION = finalAttrs.version;
      BRANCH = "master";
      COMMIT = finalAttrs.src.rev;
    };

    # cmake installs the web UI from assets/web in the build directory.
    preBuild = ''
      cp -r --no-preserve=mode ${finalAttrs.ui} assets/web
    '';

    # The web-ui target would run npm, so build only the binary.
    buildFlags = ["sunshine"];

    # Redefined to avoid the default `make install` building the web-ui target.
    installPhase = ''
      runHook preInstall

      cmake --install .

      runHook postInstall
    '';

    dontWrapQtApps = true;

    postFixup = ''
      wrapProgram $out/bin/sunshine "''${qtWrapperArgs[@]}"
    '';

    doInstallCheck = true;
    nativeInstallCheckInputs = [udevCheckHook];

    meta = {
      description = "Game stream host for Moonlight";
      homepage = "https://github.com/SunshineStream/Sunshine";
      license = lib.licenses.gpl3Only;
      mainProgram = "sunshine";
      platforms = ["x86_64-linux"];
    };
  })
