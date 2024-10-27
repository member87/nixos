{...}: {
  services.displayManager.sddm = {
    catppuccin.enable = false;
    enable = true;
  };

  services.xserver = {
    enable = true;
    xkb.layout = "gb";
    windowManager.i3.enable = true;

    xrandrHeads = [
      {
        output = "Virtual-1";
        monitorConfig = ''
          Option "PreferredMode" "1920x1080"
        '';
      }
    ];
  };
}
