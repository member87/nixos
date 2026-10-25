import QtQuick
import QtQuick.Layouts
import qs.common

// a button surface: children are laid out in a row; hover tints with the
// accent like every ags button (`transition: background-color 0.2s`)
MouseArea {
  id: root

  default property alias content: box.data
  property alias spacing: box.spacing
  property alias radius: bg.radius
  property color color: "transparent"
  property color hoverColor: Theme.accentHover
  property color pressColor: Theme.accentActive
  property int padX: 0
  property int padY: 0
  // stretch the row across the whole button instead of centring it
  property bool fill: false

  hoverEnabled: true
  cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
  implicitWidth: box.implicitWidth + padX * 2
  implicitHeight: box.implicitHeight + padY * 2
  opacity: enabled ? 1 : 0.5

  Rectangle {
    id: bg
    anchors.fill: parent
    radius: 8
    color: !root.enabled ? root.color : root.pressed ? root.pressColor : root.containsMouse ? root.hoverColor : root.color

    Behavior on color {
      ColorAnimation {
        duration: 200
      }
    }
  }

  RowLayout {
    id: box
    x: root.fill ? root.padX : (root.width - width) / 2
    y: root.padY
    width: root.fill ? root.width - root.padX * 2 : implicitWidth
    height: root.height - root.padY * 2
    spacing: 4
  }
}
