{hostname, ...}: {
  imports = [
    ./services
    ./programs.nix
    ./nh.nix
    ./locale.nix
  ];

  networking.hostName = hostname;
  networking.nameservers = [
    "1.1.1.1"
    "1.0.0.1"
    "192.168.1.1"
  ];
  networking.dhcpcd.extraConfig = ''
    nohook resolv.conf
  '';

  users.groups.plugdev = {};
}
