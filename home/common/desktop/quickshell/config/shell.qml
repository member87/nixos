//@ pragma IconTheme oomox-gruvbox-dark

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.bar
import qs.desktop
import qs.notifications
import qs.osd
import qs.polkit
import qs.services

ShellRoot {
  // one bar per monitor
  Variants {
    model: Quickshell.screens

    Bar {}
  }

  // the widgets of an empty workspace, under the windows
  Variants {
    model: Quickshell.screens

    Desktop {}
  }

  // one of each, on the focused monitor
  Popups {}
  Osd {}
  PolkitDialog {}

  // `qs -c bar ipc call menu toggle network` - opens on the focused monitor;
  // pages: main, network, bluetooth, notifications
  IpcHandler {
    target: "menu"
    function toggle(page: string): void {
      // focusedMonitor stays null until hyprland sends its first focus event
      const screen = Hyprland.focusedMonitor?.name ?? Quickshell.screens[0]?.name ?? "";
      Menus.toggle(screen, page || "main");
    }
  }
}
