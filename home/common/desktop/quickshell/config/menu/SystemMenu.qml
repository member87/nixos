import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common
import qs.components
import qs.services

// the popover under the status icons; pages: main, network, bluetooth
PopupWindow {
  id: root

  required property var bar
  required property Item anchorItem
  readonly property bool wanted: Menus.screen === bar.screen.name
  // tall pages scroll instead of running off a small (laptop) screen
  readonly property int maxHeight: bar.screen.height - Theme.barHeight - 40

  anchor.item: anchorItem
  anchor.edges: Edges.Bottom
  anchor.gravity: Edges.Bottom
  // the panel keeps its 4px gap below the bar; the shadow margin overlaps it
  anchor.margins.top: 4 - surface.shadow
  anchor.adjustment: PopupAdjustment.Slide
  // outside clicks dismiss it, and the password field gets the keyboard
  grabFocus: true
  visible: false
  color: "transparent"
  implicitWidth: Theme.menuWidth + surface.shadow * 2
  implicitHeight: Math.min(page.implicitHeight + 20, maxHeight) + surface.shadow * 2
  mask: Region {
    item: surface.panel
  }

  onWantedChanged: visible = wanted
  onVisibleChanged: {
    if (!visible && wanted)
      Menus.close();
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
