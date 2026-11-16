{
  lib,
  buildGoModule,
  # Cross-compile beamcat.exe for players on Windows. Pure Go, so no cross toolchain.
  # (Not `windows`: callPackage would fill that from pkgs.windows.)
  forWindows ? false,
}:
buildGoModule {
  pname =
    if forWindows
    then "beamcat-windows"
    else "beamcat";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [./go.mod ./go.sum ./main.go];
  };

  vendorHash = "sha256-pZRX9v4pK2rjTJzqrc9yi1Kiu4cSGg0JH6q45W1TjBM=";

  env.CGO_ENABLED = "0";

  ldflags = ["-s" "-w"];

  # buildGoModule pins GOOS/GOARCH to the host platform in env, so switch them here. The
  # build then lands in $GOPATH/bin/windows_amd64; put the .exe at $out/bin.
  preBuild = lib.optionalString forWindows ''
    export GOOS=windows GOARCH=amd64
  '';
  doCheck = !forWindows;
  postInstall = lib.optionalString forWindows ''
    mv $out/bin/windows_amd64/beamcat.exe $out/bin/beamcat.exe
    rmdir $out/bin/windows_amd64
  '';

  meta = {
    description = "Carry a BeamMP server's TCP and UDP port over a tailcat tunnel";
    mainProgram = "beamcat";
    platforms = ["x86_64-linux"];
  };
}
