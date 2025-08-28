{...}: {
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;

    wireplumber.extraConfig = {
      "wireplumber.settings" = {
        "bluetooth.autoswitch-to-headset-profile" = true;
      };
    };
  };
}
