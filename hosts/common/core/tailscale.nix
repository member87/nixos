{username, ...}: {
  services.tailscale = {
    enable = true;
    # the operator runs `tailscale up / down / set / logout` without root:
    # the bar's network tab switches Tailscale through them
    # (home/common/desktop/quickshell/config/services/Tailscale.qml)
    extraSetFlags = ["--operator=${username}"];
  };
}
