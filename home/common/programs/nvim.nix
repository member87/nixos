{
  config,
  pkgs,
  lib,
  ...
}: let
  nvimConfigRepo = "https://github.com/member87/nvim";
  nvimConfigPath = "${config.home.homeDirectory}/.config/neovim";
in {
  # Bootstrap only: the checkout is yours to pull. Offline, warn instead of failing the switch.
  home.activation.cloneNvimConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -d "${nvimConfigPath}" ]; then
      run ${pkgs.git}/bin/git clone "${nvimConfigRepo}" "${nvimConfigPath}" \
        || warnEcho "Could not clone ${nvimConfigRepo} into ${nvimConfigPath}; it will be retried on the next switch."
    fi
  '';
}
