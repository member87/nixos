import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.components

Row {
  id: root
  spacing: 10
  leftPadding: 2
  rightPadding: 2

  Repeater {
    model: SystemTray.items

    MouseArea {
      id: button

      required property SystemTrayItem modelData

      width: 20
      height: 20
      anchors.verticalCenter: parent?.verticalCenter
      acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor

      onClicked: e => {
        if (e.button === Qt.MiddleButton)
          modelData.secondaryActivate();
        else if (modelData.hasMenu)
          // the click that dismissed the open menu lands here too: keep it closed
          menu.visible = !menu.visible && Date.now() - menu.closedAt > 250;
        else
          modelData.activate();
      }
      onWheel: e => modelData.scroll(e.angleDelta.y, false)

      IconImage {
        anchors.centerIn: parent
        implicitSize: 16
        source: button.modelData.icon
      }

      Tooltip {
        target: button
        hovered: button.containsMouse && !menu.visible
        text: {
          const t = button.modelData.tooltipTitle || button.modelData.title;
          const d = button.modelData.tooltipDescription;
          return d ? `<b>${t}</b><br>${d}` : t;
        }
      }

      TrayMenu {
        id: menu
        target: button
        handle: button.modelData.menu
      }
    }
  }
}
