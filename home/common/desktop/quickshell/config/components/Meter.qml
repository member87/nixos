import QtQuick
import qs.common

// read-only 6px bar (the ags battery `progressbar`)
Rectangle {
  property real fraction: 0

  implicitWidth: 120
  implicitHeight: 6
  radius: 3
  color: Theme.accentActive

  Rectangle {
    width: Math.max(0, Math.min(1, parent.fraction)) * parent.width
    height: parent.height
    radius: 3
    color: Theme.accent
  }
}
