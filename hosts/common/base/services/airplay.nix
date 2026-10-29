{pkgs, ...}: {
  # AirPlay mirroring receiver: run `uxplay -p`, then pick this host under
  # Screen Mirroring on macOS/iOS. Discovery uses avahi (chromecast.nix);
  # uxplay registers its service through avahi-daemon, so publishing must
  # be allowed.
  environment.systemPackages = [pkgs.uxplay];

  services.avahi.settings.publish = {
    disable-publishing = false;
    disable-user-service-publishing = false;
    publish-addresses = true;
  };

  # Fixed ports used by `uxplay -p`.
  networking.firewall = {
    allowedTCPPorts = [7000 7001 7100];
    allowedUDPPorts = [6000 6001 7011];
  };
}
