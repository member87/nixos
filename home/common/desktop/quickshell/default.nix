{
  config,
  osConfig,
  pkgs,
  ...
}: let
  # drawn by desktop/Wallpaper.qml, which finds it through QS_WALLPAPER;
  # the desktop's layout is measured against it (desktop/Desktop.qml)
  wallpaper = pkgs.fetchurl {
    url = "https://cdn.lab.jackhumes.com/background.jpg";
    sha256 = "sha256-oyDi8qJv9vq/Z5YYpDREjZlt/4IV3DL50etwIPiI7zM=";
  };

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

  # signs in to the Spotify Web API and hands out access tokens for the
  # music drawer's Up next and likes (config/services/Spotify.qml). The
  # Spotify app's client ID (developer.spotify.com, Development Mode, its
  # owner on Premium, redirect URI http://127.0.0.1:8898/callback) is read
  # at run time from its agenix secret (hosts/common/desktop/spotify.nix),
  # so it is in neither the repo nor the store in plain text
  bar-spotify = pkgs.writers.writePython3Bin "bar-spotify" {flakeIgnore = ["E501"];} (
    builtins.replaceStrings ["@clientIdFile@" "@xdgOpen@"] [osConfig.age.secrets.spotify-client-id.path "${pkgs.xdg-utils}/bin/xdg-open"] (builtins.readFile ./bar-spotify.py)
  );

  # xdph's screen-share picker (screencopy:custom_picker_binary): runs
  # sharepicker.qml and hands its choice back on stdout, which xdph parses,
  # as "[SELECTION]<flags>/<what>"; no line is a cancel
  share-picker = pkgs.writeShellApplication {
    name = "quickshell-share-picker";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      out=$(mktemp -t quickshell-share-picker.XXXXXX)
      trap 'rm -f "$out"' EXIT
      allow=0
      for arg in "$@"; do
        if [ "$arg" = --allow-token ]; then
          allow=1
        fi
      done
      # quickshell's log would land in the stdout xdph reads
      QS_SHARE_OUT="$out" QS_SHARE_ALLOW_TOKEN="$allow" \
        ${config.programs.quickshell.package}/bin/qs -p ${config.xdg.configHome}/quickshell/bar/sharepicker.qml >/dev/null 2>&1 || true
      if [ -s "$out" ]; then
        printf '[SELECTION]%s\n' "$(cat "$out")"
      fi
    '';
  };
in {
  programs.quickshell = {
    enable = true;
    # symlinked into $XDG_CONFIG_HOME/quickshell/bar; shell.qml is the bar
    # (systemd service below), lock.qml the lock screen (hypridle's lock_cmd),
    # sharepicker.qml the screen-share picker (xdph, below)
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
    Service.Environment = ["QS_WALLPAPER=${wallpaper}"];
    # Quickshell.Networking looks for NetworkManager once, at startup, and
    # never again: started alongside it (a switch restarting both) the
    # network tab stays empty until the next restart. Wait for its bus name;
    # "-": a host without it still gets a bar.
    Service.ExecStartPre = "-${pkgs.glib.bin}/bin/gdbus wait --system --timeout 30 org.freedesktop.NetworkManager";
  };

  home.packages = [
    # the system menu's brightness slider (goes through logind, no root needed)
    pkgs.brightnessctl
    bar-cast
    bar-spotify
  ];

  # read when xdph starts: restart xdg-desktop-portal-hyprland after a change
  xdg.configFile."hypr/xdph.conf".text = ''
    screencopy {
      custom_picker_binary = ${share-picker}/bin/quickshell-share-picker
    }
  '';
}
