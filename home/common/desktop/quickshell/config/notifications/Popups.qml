import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import Quickshell.Wayland
import qs.common
import qs.components
import qs.services

// Notification popups, top right of the focused monitor, newest on top.
// Low urgency stays 5s, normal 10s, critical until dismissed (swaync's
// timeouts); an app's own timeout wins. Hovering a popup holds it.
PanelWindow {
  id: root

  screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
  // the open notification centre lists them all already
  visible: Notifs.popups.length > 0 && Menus.page !== "notifications" || Notifs.popups.length > 0 && Menus.screen === ""
  anchors {
    top: true
    right: true
  }
  margins {
    top: 8 - surface.shadow
    right: 8 - surface.shadow
  }
  WlrLayershell.namespace: "quickshell-notifications"
  WlrLayershell.layer: WlrLayer.Overlay
  color: "transparent"
  implicitWidth: 420 + surface.shadow * 2
  implicitHeight: column.implicitHeight + surface.shadow * 2
  mask: Region {
    item: column
  }

  // the popups float, so they carry the popout shadow; no panel behind them
  Item {
    id: surface

    readonly property int shadow: 16

    anchors.fill: parent

    ColumnLayout {
      id: column
      x: surface.shadow
      y: surface.shadow
      width: 420
      spacing: 8

      Repeater {
        model: Notifs.popups.slice(0, 5)

        Item {
          id: popup

          required property var modelData
          // the entry carries the live notification's copy (and any update)
          readonly property var entry: Notifs.entries.find(e => e.live === modelData) ?? null
          readonly property int timeout: {
            if (modelData.expireTimeout > 0)
              return modelData.expireTimeout;
            if (modelData.urgency === NotificationUrgency.Critical)
              return 0;
            return modelData.urgency === NotificationUrgency.Low ? 5000 : 10000;
          }

          visible: entry !== null
          Layout.fillWidth: true
          implicitHeight: entry ? card.implicitHeight : 0

          PopupShadow {
            anchors.fill: card
          }

          NotificationCard {
            id: card
            width: parent.width
            entry: popup.entry ?? {}
            // slide in from the right
            x: 0
            Component.onCompleted: slide.start()

            NumberAnimation on x {
              id: slide
              running: false
              from: 60
              to: 0
              duration: 180
              easing.type: Easing.OutCubic
            }
          }

          Timer {
            interval: popup.timeout
            running: popup.timeout > 0 && !card.hovered
            onTriggered: Notifs.hidePopup(popup.modelData)
          }
        }
      }
    }
  }
}
