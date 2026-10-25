import QtQuick
import Quickshell.Hyprland
import qs.common
import qs.components

// workspaces 1-10 always shown; the focused one sits in an 18px accent circle
Row {
  id: root

  readonly property int focusedId: Hyprland.focusedWorkspace?.id ?? -1

  spacing: 2

  Repeater {
    model: 10

    MouseArea {
      id: entry

      required property int index
      readonly property int wsId: index + 1
      readonly property bool selected: root.focusedId === wsId

      // every entry reserves the selected circle's width so switching
      // never shifts the neighbouring numbers
      width: 18
      height: Theme.barHeight
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: Hyprland.dispatch(`workspace ${wsId}`)

      Rectangle {
        anchors.centerIn: parent
        width: 18
        height: 18
        radius: 9
        color: Theme.accent
        visible: entry.selected
      }

      Txt {
        anchors.centerIn: parent
        text: entry.wsId
        color: entry.selected ? Theme.accentInk : entry.containsMouse ? Theme.fgBright : Theme.fg
      }
    }
  }

  WheelHandler {
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    onWheel: e => Hyprland.dispatch(e.angleDelta.y < 0 ? "workspace +1" : "workspace -1")
  }
}
