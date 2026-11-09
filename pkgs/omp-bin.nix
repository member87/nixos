# oh-my-pi from its release binary instead of the flake's from-source build (about a
# thousand Rust crate and bun package derivations per release). Bumped nightly by
# scripts/nightly-update.sh, which the home-ops builder runs before building.
{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  stdenv,
}: let
  version = "18.18.3";
in
  stdenvNoCC.mkDerivation {
    pname = "omp";
    inherit version;

    src = fetchurl {
      url = "https://github.com/can1357/oh-my-pi/releases/download/v${version}/omp-linux-x64";
      hash = "sha256-jJoXj+107B2iGq+30ozZg5s7DJ59YHyGzDthdzVXKfQ=";
    };

    dontUnpack = true;
    # A bun-compiled executable: the JS bundle sits after the ELF data, so leave the
    # file as it is apart from the interpreter.
    dontStrip = true;
    nativeBuildInputs = [autoPatchelfHook];
    buildInputs = [stdenv.cc.cc.lib];

    installPhase = ''
      runHook preInstall
      install -Dm755 $src $out/bin/omp
      runHook postInstall
    '';

    meta = {
      description = "OMP coding agent (release binary)";
      homepage = "https://github.com/can1357/oh-my-pi";
      mainProgram = "omp";
      platforms = ["x86_64-linux"];
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    };
  }
