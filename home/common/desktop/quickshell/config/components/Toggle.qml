import QtQuick
import qs.common

// on/off switch in swaync's dnd-switch colours
MouseArea {
  id: root

  property bool checked: false
  signal toggled

  implicitWidth: 34
  implicitHeight: 20
  hoverEnabled: true
  cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
  opacity: enabled ? 1 : 0.5
  onClicked: toggled()

  Rectangle {
    anchors.fill: parent
    radius: height / 2
    color: root.containsMouse ? Theme.border : Theme.switchTrack

    Behavior on color {
      ColorAnimation {
        duration: 200
      }
    }

    Rectangle {
      width: 14
      height: 14
      radius: 7
      anchors.verticalCenter: parent.verticalCenter
      x: root.checked ? parent.width - width - 3 : 3
      color: root.checked ? Theme.good : Theme.fg

      Behavior on x {
        NumberAnimation {
          duration: 150
          easing.type: Easing.OutCubic
        }
      }
    }
  }
}
