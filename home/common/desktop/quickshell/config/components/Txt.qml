import QtQuick
import qs.common

Text {
  color: Theme.fg
  font.family: Theme.font
  font.pixelSize: 14
  renderType: Text.NativeRendering
  verticalAlignment: Text.AlignVCenter

  // a state's colour (selected, connected, muted) eases in with its surface
  Behavior on color {
    ColorAnimation {
      duration: Theme.fast
    }
  }
}
