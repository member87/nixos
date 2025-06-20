{pkgs, ...}: {
  programs = {
    zsh.enable = true;
    steam = {
      enable = true;
      extraCompatPackages = with pkgs; [
        proton-ge-bin
      ];
    };
    gamemode.enable = true;
    git.enable = true;
  };
}
