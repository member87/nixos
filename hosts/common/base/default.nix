{hostname, ...}: {
  imports = [
    ./services
    ./programs.nix
    ./locale.nix
    ./desktop-base.nix
    ./packages.nix
  ];

  networking.hostName = hostname;
  networking.dhcpcd.extraConfig = ''
    nohook resolv.conf
  '';

  users.groups.plugdev = {};

  age.identityPaths = [
    "/home/jack/.ssh/id_ed25519"
  ];
}
