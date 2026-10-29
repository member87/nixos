import QtQuick
import qs.common
import qs.services

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
  activeFocusOnTab: enabled
  Keys.onPressed: e => {
    if (e.key !== Qt.Key_Return && e.key !== Qt.Key_Enter && e.key !== Qt.Key_Space)
      return;
    e.accepted = true;
    if (!e.isAutoRepeat)
      root.toggled();
  }

  Rectangle {
    anchors.fill: parent
    anchors.margins: -3
    radius: height / 2
    color: "transparent"
    border.width: 2
    border.color: Theme.accent
    visible: root.activeFocus && Menus.keyboard
  }

  Rectangle {
    anchors.fill: parent
    radius: height / 2
    color: root.containsMouse ? Theme.border : Theme.switchTrack

    Behavior on color {
      ColorAnimation {
        duration: Theme.base
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
          duration: Theme.base
          easing.type: Theme.easeOut
        }
      }

      Behavior on color {
        ColorAnimation {
          duration: Theme.base
        }
      }
    }
  }
}
