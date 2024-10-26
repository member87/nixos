{pkgs, ...}:
pkgs.stdenv.mkDerivation {
  name = "neovim-config";

  src = pkgs.fetchFromGitHub {
    owner = "member87";
    repo = "nvim";
    rev = "main";
    hash = "sha256-4SgbJ4Bzxc7ZZAX5I2H5HjGN0JeHfpZ0cfAdGCc0I7w=";
  };

  installPhase = ''
    cp -r $src $out
  '';
}
