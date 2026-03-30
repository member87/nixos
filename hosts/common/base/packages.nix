{
  pkgs,
  inputs,
  ...
}: let
  androidSdk = pkgs.androidenv.composeAndroidPackages {
    abiVersions = ["x86_64"];
    includeEmulator = true;
    includeSystemImages = true;
    platformVersions = ["36"];
    systemImageTypes = ["google_apis"];
  };
in {
  programs.kdeconnect.enable = true;

  environment.variables = {
    ANDROID_HOME = "${androidSdk.androidsdk}/libexec/android-sdk";
    ANDROID_SDK_ROOT = "${androidSdk.androidsdk}/libexec/android-sdk";
  };

  environment.systemPackages = with pkgs; [
    ghostty
    alejandra
    age
    agenix
    bat
    bluetui
    brave
    cargo
    curl
    darktable
    dig
    fastfetch
    ffmpeg
    fluxcd
    freecad
    hyprshot
    hyprpaper
    impala
    jellyfin-desktop
    jq
    kubectl
    just
    k9s
    kubeseal
    gcc
    go
    gnumake
    gphoto2
    killall
    lua-language-server
    ledger-live-desktop
    libnotify
    lutris
    lxqt.lxqt-openssh-askpass
    lxqt.lxqt-policykit
    mangohud
    neovim
    nodejs
    nil
    nixfmt-rfc-style
    obsidian
    openssl
    pavucontrol
    playerctl
    python3
    protontricks
    obs-studio
    rose-pine-hyprcursor
    r2modman
    ripgrep
    satty
    socat
    sops
    talosctl
    traceroute
    treefmt
    unzip
    legcord
    wineWow64Packages.stable
    wl-clipboard
    wget
    android-tools
    androidSdk.androidsdk
    inputs.opencode.packages.${pkgs.system}.default
  ];
}
