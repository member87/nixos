{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    k3s
    (wrapHelm kubernetes-helm {
      plugins = with pkgs.kubernetes-helmPlugins; [
        helm-secrets
        helm-diff
        helm-s3
        helm-git
      ];
    })
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

  environment.variables = {
    KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
  };

  services = {
    k3s = {
      enable = true;
      role = "server";
      extraFlags = toString [
        "--disable servicelb"
        "--disable traefik"
        "--disable local-storage"
      ];
    };
  };
}
