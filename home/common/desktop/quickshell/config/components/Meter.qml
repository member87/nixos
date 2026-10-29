import QtQuick
import qs.common

// read-only 6px bar (the ags battery `progressbar`)
Rectangle {
  id: root

  property real fraction: 0
  // a fraction ticked on a timer (a song's position): glide through each
  // tick at an even pace, over this many ms; 0 jumps
  property int glide: 0
  property real eased: fraction

  Behavior on eased {
    enabled: root.glide > 0
    NumberAnimation {
      duration: root.glide
    }
  }

  implicitWidth: 120
  implicitHeight: 6
  radius: 3
  color: Theme.accentActive

  Rectangle {
    width: Math.max(0, Math.min(1, root.eased)) * parent.width
    height: parent.height
    radius: 3
    color: Theme.accent
  }
}
