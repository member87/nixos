{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:
# The official release binary: building from source needs BeamMP's vcpkg setup. It
# links only libc, libm, libstdc++ and libgcc_s; Lua, OpenSSL, curl and Boost are static.
stdenv.mkDerivation (finalAttrs: {
  pname = "beammp-server";
  version = "3.9.3";

  src = fetchurl {
    url = "https://github.com/BeamMP/BeamMP-Server/releases/download/v${finalAttrs.version}/BeamMP-Server.debian.13.x86_64";
    hash = "sha256-vgmn/1IsymEiE3Qg54VAWd+9R5GIVZuilBMKbUEhoI4=";
  };

  dontUnpack = true;

  nativeBuildInputs = [autoPatchelfHook];
  buildInputs = [stdenv.cc.cc.lib];

  installPhase = ''
    runHook preInstall
    install -Dm0755 $src $out/bin/BeamMP-Server
    runHook postInstall
  '';

  meta = {
    description = "Server for BeamMP, the BeamNG.drive multiplayer mod";
    homepage = "https://github.com/BeamMP/BeamMP-Server";
    license = lib.licenses.agpl3Only;
    mainProgram = "BeamMP-Server";
    platforms = ["x86_64-linux"];
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
  };
})
