{
  config,
  pkgs,
  lib,
  ...
}: let
  nvimConfigRepo = "https://github.com/member87/nvim";
  nvimConfigPath = "${config.home.homeDirectory}/.config/neovim";
in {
  home.activation.cloneNvimConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -d "${nvimConfigPath}" ]; then
      echo "Neovim config directory ${nvimConfigPath} does not exist. Cloning from ${nvimConfigRepo}..."
      ${pkgs.git}/bin/git clone "${nvimConfigRepo}" "${nvimConfigPath}"
      echo "Neovim config cloned."
    fi
  '';
}
