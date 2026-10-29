import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.common
import qs.components
import qs.services

// The bell's popout: every notification not yet dismissed, newest first,
// with do-not-disturb and clear all. Same window kind as the system menu
// (a layer surface under a Hyprland focus grab), and the same Menus state,
// so only one of the two is open at a time.
PanelWindow {
  id: root

  required property var bar
  required property Item anchorItem
  readonly property int panelWidth: 420
  readonly property int maxHeight: bar.screen.height - Theme.barHeight - 40
  // apps whose groups are unfolded
  property var expanded: []
  readonly property real anchorX: {
    anchorItem.x;
    anchorItem.width;
    anchorItem.parent.x;
    return anchorItem.mapToItem(null, anchorItem.width / 2, 0).x;
  }

  readonly property bool wanted: Menus.screen === bar.screen.name && Menus.page === "notifications"
  // mapped from opening until the panel is back inside the bar
  property bool mapped: false

  onWantedChanged: {
    if (wanted) {
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
  exclusionMode: ExclusionMode.Ignore
  margins {
    // on the bar's bottom line, as the system menu
    top: Theme.barHeight - 1
    right: Math.max(0, bar.width - anchorX - implicitWidth / 2)
  }
  WlrLayershell.namespace: "quickshell-notification-center"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  color: "transparent"
  implicitWidth: panelWidth + drawer.ear * 2
  // the tallest it may grow; the panel eases to its content inside
  implicitHeight: maxHeight
  mask: Region {
    item: drawer.area
  }

  HyprlandFocusGrab {
    windows: [root, root.bar]
    active: root.wanted && root.visible
    onCleared: Menus.close()
  }

  BarDrawer {
    id: drawer

    targetHeight: Math.min(body.implicitHeight + 20, root.maxHeight)
    smooth: true
    onRetracted: {
      if (!root.wanted)
        root.mapped = false;
    }

    // the keyboard: arrows and Tab through the cards and buttons, Delete
    // dismisses the card in focus, Escape closes
    KeyNav {
      id: nav
      anchors.fill: parent
      flick: flick
      onCancelled: Menus.close()

      Flickable {
        id: flick
        anchors.fill: parent
        anchors.margins: 10
        contentHeight: body.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        ColumnLayout {
          id: body
          width: parent.width
          spacing: 10

          RowLayout {
            spacing: 8
            Layout.leftMargin: 6
            Layout.rightMargin: 4

            Txt {
              text: "Notifications"
              color: Theme.accent
              font.pixelSize: 15
              font.bold: true
              Layout.fillWidth: true
            }

            Txt {
              text: "Do not disturb"
              font.pixelSize: 12
            }

            Toggle {
              checked: UiState.doNotDisturb
              onToggled: Notifs.toggleDoNotDisturb()
            }
          }

          UndoBar {}

          Section {
            visible: Notifs.count === 0 && !Notifs.cleared

            Txt {
              text: UiState.doNotDisturb ? "Nothing new. Popups are paused, critical ones still show" : "Nothing new"
              font.pixelSize: 12
              wrapMode: Text.Wrap
              Layout.fillWidth: true
            }
          }

          Repeater {
            model: Notifs.groups

            NotificationGroup {
              required property var modelData

              app: modelData.app
              items: modelData.items
              // kept by app name: a new notification rebuilds the groups
              open: root.expanded.includes(modelData.app)
              Layout.fillWidth: true
              onToggled: root.expanded = open ? root.expanded.filter(a => a !== modelData.app) : [...root.expanded, modelData.app]
            }
          }

          TextButton {
            visible: Notifs.count > 1
            text: "Clear all"
            Layout.alignment: Qt.AlignRight
            onClicked: Notifs.clearAll()
          }
        }
      }
    }
  }
}
