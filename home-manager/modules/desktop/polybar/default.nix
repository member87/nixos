{pkgs, ...}: 

let
  # spotifyScriptPath = "${pkgs.polybar-spotify-script}/bin/polybar-spotify-script";
  spotifyScriptContent = builtins.readFile ./spotify.sh;
  spotifyScriptPath = "${(pkgs.writeShellApplication {
    name = "polybar-spotify-script";
    runtimeInputs = [ pkgs.playerctl ];
    text = spotifyScriptContent;
  })}/bin/polybar-spotify-script";
in 
{

  services.polybar = {
    enable = false;

    script = "polybar bottom &";

    package = pkgs.polybar.override {
      i3Support = true;
      i3 = pkgs.i3;
    };

    config = {
      "bar/bottom" = {
        height = "25";
        modules-left = "i3 spotify";
        modules-right = "download cpu memory pulseaudio date time";
        bottom = true;
        background = "\${colors.crust}";
        foreground = "\${colors.text}";
        font-0 = "RobotoMono Nerd Font:size=10;3";
        font-1 = "Font Awesome 6 Free Solid:style=Solid;3";
      };

      "module/i3" = {
        type = "internal/i3";
        format = "<label-state> <label-mode>";
        label-mode = "%mode%";
        label-mode-padding = 1;

        label-focused-foreground = "\${colors.lavender}";
        label-focused-background = "\${colors.surface0}";
        label-focused-padding = 1;

        label-unfocused-foreground = "\${colors.foreground}";
        label-unfocused-padding = 1;
      };

      "module/time" = {
        type = "internal/date";
        interval = 1;
        time = "%H:%M";
        label = "%time%";
        label-padding = 1;
        label-foreground = "\${colors.subtext0}";
        format-prefix = "";
        format-prefix-padding = 1;
        format-prefix-font = 1;
      };

      "module/date" = {
        type = "internal/date";
        interval = 1;
        date = "%d-%m-%Y";
        label = "%date%";
        label-foreground = "\${colors.subtext0}";
        label-padding = 1;
        format-prefix = "";
        format-prefix-padding = 1;
      };

      "module/pulseaudio" = {
        type = "internal/pulseaudio";
        interval = 1;
        format-volume = "<ramp-volume><label-volume>";
        ramp-volume-0 = "";
        ramp-volume-1 = "";
        ramp-volume-2 = " ";     
      };

      "module/memory" = {
        type = "internal/memory";
        label = "%percentage_used:02%%";
        label-foreground = "\${colors.subtext0}";
        label-padding = 1;
        interval = 5;
        format-prefix = "";
        format-prefix-font = 1;
        format-prefix-padding = 1;
      };

      "module/cpu" = {
        type = "internal/cpu";
        label = "%percentage:02%%";
        label-foreground = "\${colors.subtext0}";
        label-font = 0;
        label-padding = 1;
        format-prefix = "";
        format-prefix-padding = 1;
      };

      "module/download" = {
        type = "internal/network";
        interface = "enp1s0";
        unkown-as-up = true;
        format-connected = "<label-connected>";
        label-connected  = "%downspeed:%";
        label-connected-foreground = "\${colors.subtext0}";
        label-connected-padding = 1;
        format-connected-prefix = "";
        format-connected-prefix-padding = 1;
        format-connected-font = 1;
      };

      "module/spotify" = {
        type = "custom/script";
        interval = 1;
        format = "<label>";
        format-prefix = "";
        format-prefix-margin = 2;
        exec = "${spotifyScriptPath}";
      };
    };
  };
}


