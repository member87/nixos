{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    alejandra
    agenix
    bat
    curl
    gcc
    jq
    killall
    lua-language-server
    unstable.neovim
    nil
    ripgrep
    unzip
    wget
  ];
}
