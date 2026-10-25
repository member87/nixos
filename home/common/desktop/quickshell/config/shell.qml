//@ pragma IconTheme oomox-gruvbox-dark

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.bar
import qs.services

ShellRoot {
  // one bar per monitor
  Variants {
    model: Quickshell.screens

    Bar {}
  }

  // `qs -c bar ipc call menu toggle network` - opens on the focused monitor;
  // pages: main, network, bluetooth
  IpcHandler {
    target: "menu"
    function toggle(page: string): void {
      // focusedMonitor stays null until hyprland sends its first focus event
      const screen = Hyprland.focusedMonitor?.name ?? Quickshell.screens[0]?.name ?? "";
      Menus.toggle(screen, page || "main");
    }
  }
}
