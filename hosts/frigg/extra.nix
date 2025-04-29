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
    helmfile
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
    openiscsi
  ];

  environment.variables = {
    KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
  };

  services.openiscsi = {
    enable = true;
    name = "iqn.2025-04.local.homelab:frigg";
  };

  system.activationScripts.usrlocalbin = ''
    mkdir -m 0755 -p /usr/local
    ln -nsf /run/current-system/sw/bin /usr/local/
  '';

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
