{...}: {
  # DBus battery/power daemon. Not enabled previously - needed by the
  # quickshell bar (Quickshell.Services.UPower) and generally useful for any battery-status
  # consumer. Harmless on desktops with no battery (reports zero devices).
  services.upower.enable = true;
}
