//@ pragma IconTheme oomox-gruvbox-dark

// The lock screen, a second shell over the same config folder as the bar:
//   qs -p ~/.config/quickshell/bar/lock.qml -n
// It runs only while locked (hypridle's lock_cmd starts it) and exits on
// unlock. QS_LOCK_PREVIEW=1 draws it in ordinary windows without locking;
// Escape closes the preview.

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.lock

ShellRoot {
  id: root

  readonly property bool preview: Quickshell.env("QS_LOCK_PREVIEW") === "1"

  LockContext {
    id: lockContext
    onUnlocked: release.start()
  }

  // let the surfaces play their exit before the session is released
  Timer {
    id: release
    interval: 380
    onTriggered: {
      if (root.preview) {
        Qt.quit();
        return;
      }
      // WlSessionLock does not signal `locked` turning false once the
      // compositor has let go, so exit here, after a moment for the unlock
      // request to reach Hyprland. A lingering process would make `qs -n`
      // refuse every later lock.
      lock.locked = false;
      exit.start();
    }
  }

  Timer {
    id: exit
    interval: 250
    onTriggered: Qt.quit()
  }

  // Hyprland confirms a lock (`secure`) almost at once. One it never
  // confirms was refused (another locker holds the session); withdraw it and
  // exit rather than linger and block later locks.
  Timer {
    interval: 5000
    running: !root.preview
    onTriggered: {
      if (lock.secure)
        return;
      console.warn("session lock was not confirmed by the compositor, giving up");
      lock.locked = false;
      Qt.quit();
    }
  }

  WlSessionLock {
    id: lock
    locked: !root.preview

    WlSessionLockSurface {
      color: Theme.wallpaper

      LockSurface {
        anchors.fill: parent
        ctx: lockContext
      }
    }
  }

  Variants {
    model: root.preview ? Quickshell.screens : []

    PanelWindow {
      required property var modelData

      screen: modelData
      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "quickshell-lock-preview"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
      color: Theme.wallpaper

      LockSurface {
        anchors.fill: parent
        ctx: lockContext
        preview: true
        onLeave: Qt.quit()
      }
    }
  }
}
