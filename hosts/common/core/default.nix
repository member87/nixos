# Every host: Nix, networking, remote access, secrets and a shell toolbox.
{
  flakePath,
  pkgs,
  username,
  ...
}: {
  imports = [
    ./lan-firewall.nix
    ./locale.nix
    ./networking.nix
    ./nix-cache.nix
    ./nix.nix
    ./ssh.nix
    ./tailscale.nix
    ./wireguard.nix
  ];

  users.groups.plugdev = {};

  # Secrets are encrypted to each host's SSH host key and to jack's key on it
  # (secrets/secrets.nix); either decrypts them.
  age.identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
    "/home/${username}/.ssh/id_ed25519"
  ];

  programs = {
    zsh.enable = true;
    git.enable = true;
    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 4d --keep 3";
      flake = flakePath;
    };
  };

  environment.systemPackages = with pkgs; [
    age
    agenix
    bat
    curl
    dig
    fastfetch
    impala
    jq
    killall
    neovim
    openssl
    ripgrep
    rsync
    socat
    traceroute
    unzip
    wget
  ];
}
