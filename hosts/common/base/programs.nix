{pkgs, ...}: {
  programs = {
    zsh.enable = true;
    steam = {
      enable = true;
      package = pkgs.unstable.steam;
    };
    gamemode.enable = true;
    git.enable = true;
  };
}
