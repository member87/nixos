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
// The window keeps the tallest size the menu may reach; the panel inside it
// eases between pages and as sections unfold, and slides back into the bar
// before the window goes.
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

  readonly property bool wanted: Menus.screen === bar.screen.name && Menus.page !== "notifications"
  // mapped from opening until the panel is back inside the bar
  property bool mapped: false
  // the page drawn: kept while the menu slides away into the notification
  // centre, which Menus also calls a page
  property string shownPage: "main"

  onWantedChanged: {
    if (wanted) {
      shownPage = Menus.page;
      mapped = true;
      drawer.open();
      nav.forceActiveFocus();
    } else {
      drawer.close();
    }
  }

  screen: bar.screen
  visible: mapped
  anchors {
    top: true
    right: true
  }
  // hangs from the bar, a BarDrawer one with it: starts on the bar's bottom
  // line and covers it where they join
  exclusionMode: ExclusionMode.Ignore
  margins {
    top: Theme.barHeight - 1
    right: Math.max(0, bar.width - anchorX - implicitWidth / 2)
  }
  WlrLayershell.namespace: "quickshell-menu"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  color: "transparent"
  implicitWidth: Theme.menuWidth + drawer.ear * 2
  implicitHeight: maxHeight
  mask: Region {
    item: drawer.area
  }

  HyprlandFocusGrab {
    windows: [root, root.bar]
    active: root.wanted && root.visible
    onCleared: Menus.close()
  }

  // a page arrives from the side it lies on: the sub-pages to the right of
  // the main one
  Connections {
    target: Menus

    function onPageChanged() {
      if (Menus.page === "notifications")
        return;
      root.shownPage = Menus.page;
      // opening on a page: it comes down with the panel
      if (!root.visible || !drawer.settled)
        return;
      flick.contentY = 0;
      pageIn.from = Menus.page === "main" ? -16 : 16;
      pageIn.restart();
      pageFade.restart();
    }
  }

  NumberAnimation {
    id: pageIn
    target: pageShift
    property: "x"
    to: 0
    duration: Theme.base
    easing.type: Theme.easeOut
  }

  NumberAnimation {
    id: pageFade
    target: page
    property: "opacity"
    from: 0
    to: 1
    duration: Theme.base
    easing.type: Theme.easeOut
  }

  BarDrawer {
    id: drawer

    targetHeight: Math.min(page.implicitHeight + 20, root.maxHeight)
    smooth: true
    onRetracted: {
      if (!root.wanted)
        root.mapped = false;
    }

    // the keyboard: arrows and Tab through the controls, Escape back to
    // the main page, then out
    KeyNav {
      id: nav
      anchors.fill: parent
      flick: flick
      onCancelled: {
        if (Menus.page !== "main")
          Menus.page = "main";
        else
          Menus.close();
      }

      Flickable {
        id: flick
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
          sourceComponent: root.shownPage === "network" ? networkPage : root.shownPage === "bluetooth" ? bluetoothPage : mainPage
          transform: Translate {
            id: pageShift
          }
        }
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
