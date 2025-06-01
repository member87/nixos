{
  lib,
  stdenv,
  fetchFromGitHub,
  vcpkg,
  httplib,
  openssl,
  nlohmann_json,
  curl,
  cmake,
  zlib,
}:
stdenv.mkDerivation rec {
  pname = "beammp-launcher";
  version = "2.4.1";

  src = fetchFromGitHub {
    owner = "BeamMP";
    repo = "BeamMP-Launcher";
    rev = "v${version}";
    hash = "sha256-9ScsctCuhRL8XiLKYxLrKpb6rj2tsPUXqs9eN2mcTIQ=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [cmake];

  buildInputs = [
    zlib
    httplib
    nlohmann_json
    openssl
    curl
  ];

  cmakeFlags = ["-DCMAKE_BUILD_TYPE=Release"];
  enableParallelBuilding = true;

  installPhase = ''
    install BeamMP-Launcher -D -t $out/bin
  '';

  meta = {
    homepage = "https://github.com/BeamMP/BeamMP-Launcher";
    description = "Official BeamMP Launcher";
    license = [lib.licenses.unfree];
    maintainers = with lib.maintainers; [JManch];
    mainProgram = "BeamMP-Launcher";
  };
}
