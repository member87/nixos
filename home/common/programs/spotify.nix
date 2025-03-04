{
  lib,
  config,
  inputs,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    spotify
  ];
}
