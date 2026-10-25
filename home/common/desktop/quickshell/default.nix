{pkgs, ...}: let
  # casts this computer's audio to a Chromecast; driven by the output chooser
  bar-cast = pkgs.writeShellApplication {
    name = "bar-cast";
    runtimeInputs = with pkgs; [
      avahi
      coreutils
      ffmpeg
      gawk
      gnused
      go-chromecast
      iproute2
      pulseaudio # pactl, against pipewire-pulse
      socat
    ];
    text = builtins.readFile ./bar-cast.sh;
  };
in {
  programs.quickshell = {
    enable = true;
    # symlinked into $XDG_CONFIG_HOME/quickshell/bar; shell.qml is the bar
    # (systemd service below), lock.qml the lock screen (hypridle's lock_cmd)
    configs.bar = ./config;
    activeConfig = "bar";
    systemd.enable = true;
  };

  home.packages = [
    # the system menu's brightness slider (goes through logind, no root needed)
    pkgs.brightnessctl
    bar-cast
  ];
}
