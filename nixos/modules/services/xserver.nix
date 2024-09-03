{ ... }:

{
  services.xserver = {
    enable = true;
    windowManager.i3.enable = true;

    displayManager = {
      sddm = {
        enable = true;
      };
    };

    xrandrHeads = [
      {
        output = "Virtual-1";
	monitorConfig = ''
	  Option "PreferredMode" "1600x900"
	'';
      }
    ];
  };
}
