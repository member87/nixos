{hostname, ...}: {
  networking.hostName = hostname;

  networking.wireless.iwd.enable = true;
  # iwd's own autoconnect races NetworkManager and blacklists networks with
  # an exponential backoff after a single failed association (e.g. mt7925e
  # flakiness after resume), leaving the machine offline for minutes. Hand
  # autoconnect to NetworkManager; impala still works (explicit connects).
  networking.wireless.iwd.settings.General.AutoConnect = false;
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd";
  # NM only uses its own autoconnect with the iwd backend if this is unset/
  # false; otherwise iwd's blacklist logic decides everything.
  environment.etc."NetworkManager/conf.d/wifi-iwd-autoconnect.conf".text = ''
    [device]
    wifi.iwd.autoconnect=false
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
}
