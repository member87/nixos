import QtQuick
import qs.common

// Holds one desktop widget behind the stripes. The parent clips at the
// stripe edge; on the stage's entered() the widget slides out past that edge
// (up out of the stripes when `above`, down out of them otherwise), `order`
// steps after the first, and on left() it slides back.
Item {
  id: root

  required property var stage
  property int order: 0
  property bool above: true
  // the offset that puts the widget wholly behind the stripes
  readonly property real away: above ? parent.height - y : -(y + height)

  implicitWidth: childrenRect.width
  implicitHeight: childrenRect.height
  transform: Translate {
    id: shift
  }

  Connections {
    target: root.stage
    function onEntered() {
      leave.stop();
      shift.y = root.away;
      arrive.restart();
    }
    function onLeft() {
      arrive.stop();
      leave.restart();
    }
  }

  SequentialAnimation {
    id: arrive
    PauseAnimation {
      duration: Theme.ms(root.order * 64)
    }
    NumberAnimation {
      target: shift
      property: "y"
      to: 0
      duration: Theme.stage
      easing.type: Easing.OutCubic
    }
  }

  NumberAnimation {
    id: leave
    target: shift
    property: "y"
    to: root.away
    duration: Theme.ms(180)
    easing.type: Easing.InCubic
  }
}
