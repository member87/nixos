{hostname, ...}: {
  networking.hostName = hostname;

  # NetworkManager runs the network (IP, DNS, VPNs, the bar's Wi-Fi menu);
  # iwd joins the Wi-Fi under it. iwd also decides when to connect: it holds
  # the passphrases, so a failed attempt is just retried. With NM deciding
  # (wifi.iwd.autoconnect=false), any failed join, such as the access point
  # timing out the handshake after a resume, reads to NM as a wrong password
  # (nm-device-iwd.c); with no secret agent to ask, NM blocks the profile
  # from autoconnecting until a manual connect.
  networking.wireless.iwd.enable = true;
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd";
  networking.wireless.iwd.settings = {
    # iwd sets a failed BSS aside before trying it again: by default 60 s,
    # then 30 times longer on each further failure, up to a day, which left
    # the laptop offline for minutes. 10 s every time.
    Blacklist = {
      InitialTimeout = 10;
      Multiplier = 1;
      MaximumTimeout = 10;
    };
    # while disconnected it scans from every 10 s, backing off to 300 s;
    # stop at 60 so a set-aside network is seen again soon
    Scan.MaximumPeriodicScanInterval = 60;
  };

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
