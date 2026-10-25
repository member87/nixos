// The login screen: the lock screen's design over greetd. It runs inside a
// bare Hyprland started by greetd as the "greeter" user (see
// hosts/common/base/desktop-base.nix), and exits once greetd has the session.
// Run in a normal session it is a preview: it cannot log in, power buttons
// are disabled, and Escape closes it.

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.lock

ShellRoot {
  id: root

  GreeterContext {
    id: greeterContext
    onUnlocked: launch.start()
  }

  // play the exit, then hand over; greetd wants the greeter gone promptly
  Timer {
    id: launch
    interval: 380
    onTriggered: greeterContext.launch()
  }

  Variants {
    model: Quickshell.screens

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
      WlrLayershell.namespace: "quickshell-greeter"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
      color: Theme.wallpaper

      LockSurface {
        anchors.fill: parent
        ctx: greeterContext
        powerControls: true
        preview: greeterContext.preview
        onLeave: Qt.quit()
      }
    }
  }
}
