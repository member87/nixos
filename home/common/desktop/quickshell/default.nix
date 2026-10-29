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

  systemd.user.services.quickshell = {
    # stopped with the session (Hyprland's exec-shutdown stops
    # hyprland-session.target) and started fresh by the next one's exec-once,
    # with its environment. Without it the shell outlives the compositor,
    # crash-loops at logout and hits systemd's start limit before the next
    # login can start it.
    Unit.PartOf = ["graphical-session.target"];
    # a compositor crash: retry slowly enough to stay under the start limit
    # (5 in 10s) until it is back
    Service.RestartSec = 3;
  };

  home.packages = [
    # the system menu's brightness slider (goes through logind, no root needed)
    pkgs.brightnessctl
    bar-cast
  ];
}
