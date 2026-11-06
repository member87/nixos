import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.common
import qs.components
import qs.services

// The popover under the status icons: a rail of five tabs down its left
// edge (Menus.tabs, in the wallpaper's stripe order and colours) and the
// open tab beside it. There is no overview page: the rail's glyphs report
// each tab's state, so a glance still reads volume, signal, Bluetooth and a
// waiting update.
// A layer surface with a Hyprland focus grab rather than an xdg popup: a
// popup's grab needs a fresh click, so one opened from a keybind (IPC) was
// dismissed at once and could never take keyboard input for the wifi
// password. The grab includes the bar, so its button can close the menu.
// The window keeps the tallest size the menu may reach; the panel inside it
// eases between tabs and as sections unfold, and slides back into the bar
// before the window goes.
PanelWindow {
  id: root

  required property var bar
  required property Item anchorItem
  // tall tabs scroll instead of running off a small (laptop) screen
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
  // the tab drawn: kept while the menu slides away into the notification
  // centre, which Menus also calls a page
  property string shownPage: Menus.defaultTab

  onWantedChanged: {
    if (wanted) {
      shownPage = Menus.page;
      mapped = true;
      drawer.open();
      nav.forceActiveFocus();
      // the NixOS tab's flag: main on GitHub, checked as the menu opens
      Updates.refresh();
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

  // a tab arrives from the side it lies on: from below when it sits lower
  // on the rail than the one it replaces, from above otherwise
  Connections {
    target: Menus

    function onPageChanged() {
      if (Menus.page === "notifications")
        return;
      const from = Menus.tabs.indexOf(root.shownPage);
      root.shownPage = Menus.page;
      // opening on a tab: it comes down with the panel
      if (!root.visible || !drawer.settled)
        return;
      flick.contentY = 0;
      pageIn.from = Menus.tabs.indexOf(Menus.page) > from ? 16 : -16;
      pageIn.restart();
      pageFade.restart();
    }
  }

  NumberAnimation {
    id: pageIn
    target: pageShift
    property: "y"
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

    targetHeight: Math.min(Math.max(rail.implicitHeight, page.implicitHeight + 20), root.maxHeight)
    smooth: true
    onRetracted: {
      if (!root.wanted)
        root.mapped = false;
    }

    // the keyboard: arrows and Tab through the open tab's controls and then
    // the rail, 1-5 straight to a tab, Escape out
    KeyNav {
      id: nav
      anchors.fill: parent
      flick: flick
      onCancelled: Menus.close()
      onUnhandled: e => {
        const n = e.key - Qt.Key_1;
        if (e.modifiers !== Qt.NoModifier || n < 0 || n >= Menus.tabs.length)
          return;
        e.accepted = true;
        Menus.page = Menus.tabs[n];
      }

      // first in the focus chain, so Tab starts in the open tab
      Flickable {
        id: flick
        anchors.left: rail.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: 12
        anchors.rightMargin: 10
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        contentHeight: page.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        Loader {
          id: page
          width: parent.width
          // tabs are built on open and torn down on close (and on leaving
          // them), so wifi scans, bluetooth discovery and nmcli polling
          // only run while their tab shows
          active: root.visible
          sourceComponent: {
            switch (root.shownPage) {
            case "power":
              return powerPage;
            case "network":
              return networkPage;
            case "bluetooth":
              return bluetoothPage;
            case "nixos":
              return nixosPage;
            default:
              return soundPage;
            }
          }
          transform: Translate {
            id: pageShift
          }
        }
      }

      // The rail. The open tab's fill runs through the rule into the page,
      // a divider tab in a manual; it slides to the tab chosen.
      Item {
        id: rail

        readonly property int tabHeight: 34
        readonly property int gap: 4
        readonly property int index: Math.max(0, Menus.tabs.indexOf(root.shownPage))
        readonly property bool updateWaiting: Updates.outOfDate && Updates.error === ""

        // each tab's glyph reports its state
        function glyph(tab: string): string {
          switch (tab) {
          case "power":
            return Icons.power;
          case "network":
            return Net.icon;
          case "sound":
            return Icons.volume(Math.round(Audio.volume * 100), Audio.muted);
          case "bluetooth":
            return Bt.powered ? (Bt.connected.length > 0 ? Icons.bluetoothConnected : Icons.bluetoothOn) : Icons.bluetoothOff;
          default:
            return Icons.nixos;
          }
        }

        width: 46
        height: parent.height
        implicitHeight: tabs.implicitHeight + 20

        Rectangle {
          x: parent.width - 1
          width: 1
          height: parent.height
          color: Theme.rule
        }

        // the open tab's fill, over the rule
        Rectangle {
          x: tabs.x
          y: tabs.y + rail.index * (rail.tabHeight + rail.gap)
          width: parent.width - tabs.x
          height: rail.tabHeight
          topLeftRadius: Theme.radiusControl + 2
          bottomLeftRadius: Theme.radiusControl + 2
          color: Theme.stripes[rail.index]

          Behavior on y {
            enabled: drawer.settled
            NumberAnimation {
              duration: Theme.base
              easing.type: Theme.easeOut
            }
          }
          Behavior on color {
            enabled: drawer.settled
            ColorAnimation {
              duration: Theme.base
            }
          }
        }

        Column {
          id: tabs
          x: 6
          y: 10
          spacing: rail.gap

          Repeater {
            model: Menus.tabs

            RailTab {
              required property string modelData
              required property int index

              tab: modelData
              label: {
                switch (modelData) {
                case "power":
                  return "Power";
                case "network":
                  return "Network";
                case "sound":
                  return "Sound";
                case "bluetooth":
                  return "Bluetooth";
                default:
                  return rail.updateWaiting ? "NixOS: update waiting" : "NixOS";
                }
              }
              stripe: Theme.stripes[index]
              glyph: rail.glyph(modelData)
              flagged: modelData === "nixos" && rail.updateWaiting
              current: root.shownPage === modelData
              implicitHeight: rail.tabHeight
              // up to the rule; the marker alone runs over it into the page
              implicitWidth: rail.width - tabs.x - 1
            }
          }
        }
      }
    }
  }

  Component {
    id: soundPage
    SoundPage {}
  }

  Component {
    id: powerPage
    PowerPage {}
  }

  Component {
    id: networkPage
    NetworkPage {}
  }

  Component {
    id: bluetoothPage
    BluetoothPage {}
  }

  Component {
    id: nixosPage
    NixosPage {}
  }
}
