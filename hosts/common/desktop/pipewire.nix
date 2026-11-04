{...}: {
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;

    wireplumber.extraConfig = {
      # Make sure A2DP (high quality, output-only) is preferred over the
      # low quality bidirectional HSP/HFP "headset" profile, and enable the
      # better codecs. Without this, some devices only ever expose a
      # headset-head-unit profile with no usable output ("sink").
      "51-bluez-config" = {
        "monitor.bluez.properties" = {
          "bluez5.roles" = ["a2dp_sink" "a2dp_source" "bap_sink" "bap_source" "hsp_hs" "hsp_ag" "hfp_hf" "hfp_ag"];
          "bluez5.codecs" = ["sbc" "sbc_xq" "aac" "aptx" "aptx_hd" "ldac"];
          "bluez5.enable-sbc-xq" = true;
          "bluez5.enable-msbc" = true;
          "bluez5.enable-hw-volume" = true;
          "bluez5.hfphsp-backend" = "native";
        };
      };

      # NOTE: the section name ("wireplumber.settings") must be the inner
      # key, not the outer/filename key, or wireplumber silently ignores it.
      "52-wireplumber-settings" = {
        "wireplumber.settings" = {
          "bluetooth.autoswitch-to-headset-profile" = false;
        };
      };
    };
  };
}
