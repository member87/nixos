{...}: {
  home.file.".config/winapps/winapps.conf" = {
    text = ''
    RDP_USER="Docker"
    RDP_PASS="password"
    RDP_IP="192.168.1.203"
    WAFLAVOR="manual"
    RDP_FLAGS="/cert:tofu /sound /microphone /size:1280x720	/multimon"
    '';
  };
}
