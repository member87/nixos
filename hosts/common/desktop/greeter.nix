{
  pkgs,
  config,
  lib,
  username,
  ...
}: let
  hyprland = config.programs.hyprland.package;
  fprint = config.services.fprintd.enable;
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
    ${lib.optionalString fprint "export QS_GREETER_FINGERPRINT=1"}
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
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${hyprland}/bin/start-hyprland -- --config ${greeterHyprland}";
        user = "greeter";
      };
    };
  };

  # greetd runs one PAM conversation and cannot interrupt a module, so the
  # login stack (which on thor starts with pam_fprintd and waits on its
  # timeout) is swapped for: fingerprint, unlimited, then the lock screen's
  # password-only stack (lockscreen.nix). The greeter starts a scan with the
  # screen and ends it on the first key typed by stopping fprintd, which
  # pam_fprintd takes as a give-up (GreeterContext.qml).
  security.pam.services.greetd.rules.auth = lib.mkForce ({
      quickshell-lock = {
        order = 10000;
        control = "substack";
        modulePath = "quickshell-lock";
      };
    }
    // lib.optionalAttrs fprint {
      fprintd = {
        order = 9000;
        control = "sufficient";
        modulePath = "${config.services.fprintd.package}/lib/security/pam_fprintd.so";
        settings.timeout = -1;
      };
    });

  security.polkit.extraConfig = lib.mkIf fprint ''
    // the greeter ends its fingerprint scan when you type (greeter.nix)
    polkit.addRule(function (action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          action.lookup("unit") == "fprintd.service" &&
          action.lookup("verb") == "stop" &&
          subject.user == "greeter")
        return polkit.Result.YES;
    });
  '';

  # Secret Service (org.freedesktop.secrets) for apps that store credentials,
  # e.g. Chromium's Safe Storage key. The module unlocks the keyring in
  # `login`'s stack, but greetd's auth runs through quickshell-lock above, so
  # that stack has to hand the password over; `login`'s session (included by
  # greetd) starts the daemon with it. A fingerprint login has no password to
  # hand over: the keyring starts locked and asks (gcr) when first used.
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.quickshell-lock.enableGnomeKeyring = true;
}
