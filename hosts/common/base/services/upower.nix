{...}: {
  # DBus battery/power daemon. Not enabled previously - needed by AstalBattery
  # (used by the AGS bar) and generally useful for any battery-status
  # consumer. Harmless on desktops with no battery (reports zero devices).
  services.upower.enable = true;
}
