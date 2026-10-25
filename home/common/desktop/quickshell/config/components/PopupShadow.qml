import QtQuick
import QtQuick.Effects

// the drop shadow under anything that floats (popouts, notification popups);
// anchor it to the floating panel, with room around it in the window
RectangularShadow {
  radius: 8
  offset.y: 3
  blur: 12
  color: Qt.rgba(0, 0, 0, 0.7)
}
