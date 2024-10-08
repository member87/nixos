{
  lib,
  config,
  ...
}: {
  programs.zsh = {
    enable = true;

    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      vim = "nvim";
    };

    history = {
      size = 5000;
      path = "${config.xdg.dataHome}/zsh/history";
    };

    oh-my-zsh = {
      enable = true;
      plugins = [
        "zoxide"
        "starship"
        "sudo"
        "ssh"
        "ssh-agent"
        "npm"
        "git"
        "aliases"
        "colored-man-pages"
        "docker"
      ];
    };
  };
}
