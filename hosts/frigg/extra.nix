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
    neovim
    nil
    ripgrep
    unzip
    wget
    # openiscsi
  ];

  environment.variables = {
    KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
  };

  systemd.tmpfiles.rules = [
    "d /usr/bin 0755 root root -"
    "L /usr/bin/iscsiadm - - - - ${pkgs.openiscsi}/bin/iscsiadm"
  ];

  # environment.etc."iscsi/iscsiadm_symlink" = {
  #   source = "${pkgs.openiscsi}/bin/iscsiadm";
  #   target = "/usr/bin/iscsiadm";
  #   mode = "0755";
  # };

  services.openiscsi = {
    enable = true;
    name = "iqn.2025-04.local.homelab:frigg";
  };

  services = {
    k3s = {
      enable = true;
      role = "server";
    };
  };
}
