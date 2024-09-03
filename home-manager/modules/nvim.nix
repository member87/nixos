{ pkgs, ... }:


let

  neovimConfig = pkgs.fetchFromGitHub {
    owner = "member87";
    repo = "nvim";
    rev = "main";
    sha256 = "sha256-4SgbJ4Bzxc7ZZAX5I2H5HjGN0JeHfpZ0cfAdGCc0I7w=";
  };
in
{
  home.file.".config/nvim" = {
    source = neovimConfig;
    text = null;
  };
}
