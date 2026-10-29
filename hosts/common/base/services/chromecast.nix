{
  # Chromecast discovery (mDNS) and casting from Google Chrome.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true; # UDP 5353
  };

  # Chrome's Cast/DIAL discovery receives SSDP replies unicast on ephemeral
  # ports, which the stateful firewall does not match as related traffic.
  # https://github.com/NixOS/nixpkgs/issues/49630
  networking.firewall.allowedUDPPortRanges = [
    {
      from = 32768;
      to = 60999;
    }
  ];

  # bar-cast (home/common/desktop/quickshell) serves the audio it casts on
  # this port; the Chromecast fetches it from here. Only listening while
  # a cast is running.
  networking.firewall.allowedTCPPorts = [8095];
}
