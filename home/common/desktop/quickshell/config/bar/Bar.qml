import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.menu
import qs.notifications

PanelWindow {
  id: bar

  required property var modelData

  screen: modelData
  anchors {
    top: true
    left: true
    right: true
  }
  implicitHeight: Theme.barHeight
  color: Theme.bg
  WlrLayershell.namespace: "quickshell-bar"

  Item {
    anchors.fill: parent
    anchors.leftMargin: 10
    anchors.rightMargin: 10

    Workspaces {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
    }

    Music {
      anchors.centerIn: parent
    }

    RowLayout {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: 4

      Tray {}

      Privacy {}

      Indicators {
        id: indicators
        screenName: bar.screen.name
      }

      Notifications {
        id: bell
        screenName: bar.screen.name
      }

      Clock {}
    }
  }

  SystemMenu {
    bar: bar
    anchorItem: indicators
  }

  NotificationCenter {
    bar: bar
    anchorItem: bell
  }
}
