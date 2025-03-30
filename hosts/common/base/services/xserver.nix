{...}: {
  services.xserver = {
    enable = true;
    xkb.layout = "gb";

    windowManager.i3.enable = true;
    videoDrivers = ["amdgpu"];

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
