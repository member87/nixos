{
  inputs,
  pkgs,
  config,
  lib,
  username,
  ...
}: let
  hyprland = config.programs.hyprland.package;
  # the same QML as the bar and lock screen (home/common/desktop/quickshell)
  quickshellConfig = ../../../home/common/desktop/quickshell/config;

  # runs inside the greeter's Hyprland; when greetd has the session the
  # greeter quits and takes its compositor with it, so greetd can start it
  greeter = pkgs.writeShellScript "quickshell-greeter" ''
    # the greeter user's home is /var/empty
    export XDG_CACHE_HOME="$XDG_RUNTIME_DIR/greeter/cache"
    export XDG_STATE_HOME="$XDG_RUNTIME_DIR/greeter/state"
    export XDG_DATA_HOME="$XDG_RUNTIME_DIR/greeter/data"
    export QS_GREETER_USER=${username}
    export QS_GREETER_SESSION=${hyprland}/bin/start-hyprland
    export QS_GREETER_DESKTOP=Hyprland
    ${pkgs.quickshell}/bin/qs -p ${quickshellConfig}/greeter.qml
    exec ${hyprland}/bin/hyprctl dispatch 'hl.dsp.exit()'
  '';

  # Lua, not hyprlang: 0.56 banners a deprecation warning over .conf configs,
  # which would sit on top of the login screen
  greeterHyprland = pkgs.writeText "greeter-hyprland.lua" ''
    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

    hl.config({
      input = { kb_layout = "gb" },
      misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
        background_color = 0xff282828,
      },
      animations = { enabled = false },
      ecosystem = { no_update_news = true, no_donation_nag = true },
    })

    hl.on("hyprland.start", function()
      hl.exec_cmd("${greeter}")
    end)
  '';
in {
  nix.settings = {
    substituters = [
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
      "https://cache.nixos.org/"
    ];
    trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  networking.wireless.iwd.enable = true;
  # iwd's own autoconnect races NetworkManager and blacklists networks with
  # an exponential backoff after a single failed association (e.g. mt7925e
  # flakiness after resume), leaving the machine offline for minutes. Hand
  # autoconnect to NetworkManager; impala still works (explicit connects).
  networking.wireless.iwd.settings.General.AutoConnect = false;
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd";
  # NM only uses its own autoconnect with the iwd backend if this is unset/
  # false; otherwise iwd's blacklist logic decides everything.
  environment.etc."NetworkManager/conf.d/wifi-iwd-autoconnect.conf".text = ''
    [device]
    wifi.iwd.autoconnect=false
  '';

  boot = {
    consoleLogLevel = 0;
    kernelParams = [
      "quiet"
      "udev.log_level=3"
      "systemd.show_status=auto"
    ];
  };

  programs.thunar.enable = true;

  services.udisks2.enable = true;
  services.gvfs.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    glibc
    zlib
  ];

  virtualisation = {
    docker.enable = true;
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${hyprland}/bin/start-hyprland -- --config ${greeterHyprland}";
        user = "greeter";
      };
    };
  };

  # greetd runs one PAM conversation, and its auth substacks `login`, which
  # on thor starts with pam_fprintd: the password would wait for the reader
  # to time out. Authenticate with the lock screen's password-only stack
  # instead (lockscreen.nix); the fingerprint stays on the lock screen.
  security.pam.services.greetd.rules.auth = lib.mkForce {
    quickshell-lock = {
      order = 10000;
      control = "substack";
      modulePath = "quickshell-lock";
    };
  };

  services.spice-vdagentd.enable = true;

  fonts.packages = with pkgs; [
    font-awesome
    monaspace
    nerd-fonts.roboto-mono
    nerd-fonts.fira-code
  ];
}
