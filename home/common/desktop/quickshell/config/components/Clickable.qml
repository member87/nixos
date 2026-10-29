import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

// a button surface: children are laid out in a row; hover tints with the
// accent like every ags button (`transition: background-color 0.2s`).
// In a popout the keyboard reaches it too (KeyNav): Enter or Space presses
// it, and an accent ring marks it while the keyboard is in use.
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
  activeFocusOnTab: enabled
  // a key press emits the click without a pointer event: handlers that
  // read the button (`e => e.button`) see null
  Keys.onPressed: e => {
    if (e.key !== Qt.Key_Return && e.key !== Qt.Key_Enter && e.key !== Qt.Key_Space)
      return;
    e.accepted = true;
    if (e.isAutoRepeat)
      return;
    flash.restart();
    root.clicked(null);
  }
  implicitWidth: box.implicitWidth + padX * 2
  implicitHeight: box.implicitHeight + padY * 2
  opacity: enabled ? 1 : 0.5

  Rectangle {
    id: bg
    anchors.fill: parent
    radius: Theme.radiusControl
    color: !root.enabled ? root.color : root.pressed || flash.running ? root.pressColor : root.containsMouse ? root.hoverColor : root.color

    // a press lands at once; hover and state changes ease
    Behavior on color {
      ColorAnimation {
        duration: root.pressed || flash.running ? Theme.ms(60) : Theme.base
      }
    }
  }

  // a key press shows as a press
  Timer {
    id: flash
    interval: 90
  }

  Rectangle {
    anchors.fill: parent
    radius: bg.radius
    color: "transparent"
    border.width: 2
    // on an accent fill (a primary button, a connected tile) the ring is ink
    border.color: Qt.colorEqual(root.color, Theme.accent) ? Theme.accentInk : Theme.accent
    visible: root.activeFocus && Menus.keyboard
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
