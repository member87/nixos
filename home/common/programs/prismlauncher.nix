{
  pkgs,
  lib,
  ...
}: let
  themesSrc = pkgs.fetchFromGitHub {
    owner = "PrismLauncher";
    repo = "Themes";
    rev = "9e921ca23a1838f87e0699517a77da5e92921a11";
    hash = "sha256-V6mkItSVA/TSC0yWKvcps/ewAC0nSd1KSBr8Pvdv8z8=";
  };

  themeId = "Gruvbox-Dark";
in {
  xdg.dataFile."PrismLauncher/themes/${themeId}".source = "${themesSrc}/themes/${themeId}";

  # PrismLauncher owns prismlauncher.cfg (window geometry, last account, java path, ...)
  # so it can't be a nix-managed symlink. Only steer the ApplicationTheme key, once,
  # via activation; leave every other line and any later in-app changes alone.
  home.activation.prismlauncherTheme = lib.hm.dag.entryAfter ["writeBoundary"] ''
    cfg="$HOME/.local/share/PrismLauncher/prismlauncher.cfg"
    if [ -f "$cfg" ] && ! $DRY_RUN_CMD grep -q "^ApplicationTheme=${themeId}$" "$cfg"; then
      if $DRY_RUN_CMD grep -q '^ApplicationTheme=' "$cfg"; then
        $DRY_RUN_CMD sed -i 's/^ApplicationTheme=.*/ApplicationTheme=${themeId}/' "$cfg"
      else
        $DRY_RUN_CMD sed -i '/^\[General\]/a ApplicationTheme=${themeId}' "$cfg"
      fi
    fi
  '';
}
