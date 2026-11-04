{flakePath, ...}: {
  programs = {
    zsh.enable = true;
    steam.enable = true;
    gamemode.enable = true;
    git.enable = true;
    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 4d --keep 3";
      flake = flakePath;
    };
  };
}
