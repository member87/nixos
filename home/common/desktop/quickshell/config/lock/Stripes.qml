import QtQuick
import qs.common

// The wallpaper's five stripes, full width, at the wallpaper's proportions.
// They are the lock's status line: they draw in from the centre on lock,
// a dark gap sweeps across them while the password is checked, they shake
// on a wrong one and fold away on unlock.
Item {
  id: root

  required property var ctx
  property real band: 20

  implicitHeight: band * 5
  clip: true
  transform: Translate {
    id: nudge
  }

  Repeater {
    model: Theme.stripes

    Rectangle {
      id: stripe

      required property color modelData
      required property int index

      y: index * root.band
      width: root.width
      height: root.band
      color: modelData
      transform: Scale {
        id: grow
        origin.x: stripe.width / 2
        origin.y: stripe.height / 2
        xScale: 0
      }

      // draw in from the centre, top stripe first
      SequentialAnimation {
        running: true
        PauseAnimation {
          duration: stripe.index * 70
        }
        NumberAnimation {
          target: grow
          property: "xScale"
          to: 1
          duration: 520
          easing.type: Easing.OutCubic
        }
      }

      // fold away on unlock, bottom stripe first
      SequentialAnimation {
        running: root.ctx.state === "unlocking"
        PauseAnimation {
          duration: (4 - stripe.index) * 40
        }
        NumberAnimation {
          target: grow
          property: "yScale"
          to: 0
          duration: 220
          easing.type: Easing.InCubic
        }
      }
    }
  }

  // the gap that sweeps across while PAM checks the password
  Rectangle {
    id: gap
    visible: root.ctx.state === "checking"
    width: root.width * 0.12
    height: root.height
    color: Theme.wallpaper

    NumberAnimation on x {
      running: gap.visible
      loops: Animation.Infinite
      from: -gap.width
      to: root.width
      duration: 900
      easing.type: Easing.InOutQuad
    }
  }

  // shake on a wrong password
  SequentialAnimation {
    id: shake
    NumberAnimation {
      target: nudge
      property: "x"
      to: -14
      duration: 50
    }
    NumberAnimation {
      target: nudge
      property: "x"
      to: 12
      duration: 70
    }
    NumberAnimation {
      target: nudge
      property: "x"
      to: -6
      duration: 70
    }
    NumberAnimation {
      target: nudge
      property: "x"
      to: 0
      duration: 60
    }
  }

  Connections {
    target: root.ctx
    function onFailuresChanged() {
      shake.restart();
    }
  }
}
