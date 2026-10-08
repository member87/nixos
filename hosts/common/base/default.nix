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

  fileSystems."/mnt/nas" = {
    device = "nas-nfs.lab.jackhumes.com:/volume1/photos";
    fsType = "nfs";
    options = [
      "nfsvers=3"
      "_netdev"
      "nofail"
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
    ];
  };

  users.groups.plugdev = {};

  age.identityPaths = [
    "/home/jack/.ssh/id_ed25519"
  ];
}
