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

  // `qs -c bar ipc call power set performance` (power-saver | balanced |
  // performance) or `... power cycle`. Registered only where the daemon is
  // (not odin); binding `enabled` also creates Power at startup, so the
  // daemon's state is loaded before the first call
  IpcHandler {
    target: "power"
    enabled: Power.available
    function set(profile: string): void {
      Power.setByName(profile);
    }
    function cycle(): void {
      Power.cycle();
    }
  }
}
