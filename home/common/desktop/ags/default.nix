{
  inputs,
  pkgs,
  ...
}: let
  astal = inputs.astal.packages.${pkgs.system};
in {
  imports = [inputs.ags.homeManagerModules.default];

  programs.ags = {
    enable = true;

    # symlinked into $XDG_CONFIG_HOME/ags
    configDir = ./config;

    systemd.enable = true;

    # astal3/astal4/astal-io are bundled by the ags package itself; every
    # other service library has to be added explicitly so gjs can `gi://` import it.
    extraPackages = with astal; [
      battery
      bluetooth
      hyprland
      mpris
      network
      tray
      wireplumber
      brightness
    ];
  };

  # AstalMpris downloads https cover art through libsoup, but the ags wrapper
  # only puts dconf on GIO_EXTRA_MODULES - without glib-networking there is no
  # TLS backend and every art download dies with "TLS support is not available"
  # (the wrapper prepends its dconf dir, so both end up on the path).
  systemd.user.services.ags.Service.Environment = [
    "GIO_EXTRA_MODULES=${pkgs.glib-networking}/lib/gio/modules"
  ];
}
