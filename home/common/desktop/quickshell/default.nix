{pkgs, ...}: {
  programs.quickshell = {
    enable = true;
    # symlinked into $XDG_CONFIG_HOME/quickshell/bar
    configs.bar = ./config;
    activeConfig = "bar";
    systemd.enable = true;
  };

  # the system menu's brightness slider (goes through logind, no root needed)
  home.packages = [pkgs.brightnessctl];
}
