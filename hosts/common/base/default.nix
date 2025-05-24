{hostname, ...}: {
  imports = [
    ./services
    ./programs.nix
    ./nh.nix
    ./locale.nix
  ];

  networking.hostName = hostname;
  networking.nameservers = [
    "192.168.1.1"
  ];
  networking.dhcpcd.extraConfig = ''
    nohook resolv.conf
  '';

  users.groups.plugdev = {};

  age.identityPaths = [
    "/home/jack/.ssh/id_ed25519"
  ];
}
