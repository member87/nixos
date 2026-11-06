pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland

// Print opens the capture in satty's fullscreen window (hyprland.nix), and
// Hyprland draws overlay layers above fullscreen windows: the notification
// popups and the OSD hold back while it is open so they do not cover the
// image. The freeze before it is kept clear by Hyprland layer rules.
Singleton {
  readonly property bool editing: ToplevelManager.toplevels.values.some(t => t.appId === "com.gabm.satty")
}
