import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.common
import qs.components
import qs.services

// The popover under the status icons; pages: main, network, bluetooth.
// A layer surface with a Hyprland focus grab rather than an xdg popup: a
// popup's grab needs a fresh click, so one opened from a keybind (IPC) was
// dismissed at once and could never take keyboard input for the wifi
// password. The grab includes the bar, so its button can close the menu.
PanelWindow {
  id: root

  required property var bar
  required property Item anchorItem
  // tall pages scroll instead of running off a small (laptop) screen
  readonly property int maxHeight: bar.screen.height - Theme.barHeight - 40
  // centre under the status icons; reads x/width so it follows layout changes
  readonly property real anchorX: {
    anchorItem.x;
    anchorItem.width;
    anchorItem.parent.x;
    return anchorItem.mapToItem(null, anchorItem.width / 2, 0).x;
  }

  screen: bar.screen
  visible: Menus.screen === bar.screen.name && Menus.page !== "notifications"
  anchors {
    top: true
    right: true
  }
  // the panel keeps a 4px gap below the bar; the shadow margin overlaps it
  exclusionMode: ExclusionMode.Ignore
  margins {
    top: Theme.barHeight + 4 - surface.shadow
    right: Math.max(0, bar.width - anchorX - implicitWidth / 2)
  }
  WlrLayershell.namespace: "quickshell-menu"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  color: "transparent"
  implicitWidth: Theme.menuWidth + surface.shadow * 2
  implicitHeight: Math.min(page.implicitHeight + 20, maxHeight) + surface.shadow * 2
  mask: Region {
    item: surface.panel
  }

  HyprlandFocusGrab {
    windows: [root, root.bar]
    active: root.visible
    onCleared: Menus.close()
  }

  PopupSurface {
    id: surface

    Flickable {
      anchors.fill: parent
      anchors.margins: 10
      contentHeight: page.implicitHeight
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      interactive: contentHeight > height

      Loader {
        id: page
        width: parent.width
        // pages are built on open and torn down on close, so wifi scans,
        // bluetooth discovery and nmcli polling only run while visible
        active: root.visible
        sourceComponent: Menus.page === "network" ? networkPage : Menus.page === "bluetooth" ? bluetoothPage : mainPage
      }
    }
  }

  Component {
    id: mainPage
    MainPage {}
  }

  Component {
    id: networkPage
    NetworkPage {}
  }

  Component {
    id: bluetoothPage
    BluetoothPage {}
  }
}
