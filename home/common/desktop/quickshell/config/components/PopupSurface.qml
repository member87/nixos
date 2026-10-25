import QtQuick
import QtQuick.Effects
import qs.common

// A popout's rounded panel with a drop shadow. The window is `shadow` px
// larger than the panel on every side so the shadow is not clipped; set the
// window's `mask` to `panel` so clicks on the shadow fall through (and count
// as outside clicks that dismiss the popout).
Item {
  id: root

  default property alias content: panel.data
  property int shadow: 16
  property alias radius: panel.radius
  property alias color: panel.color
  property alias borderWidth: panel.border.width
  property alias borderColor: panel.border.color
  readonly property alias panel: panel

  anchors.fill: parent

  RectangularShadow {
    anchors.fill: panel
    radius: panel.radius
    offset.y: 3
    blur: root.shadow - 4
    color: Qt.rgba(0, 0, 0, 0.7)
  }

  Rectangle {
    id: panel
    anchors.fill: parent
    anchors.margins: root.shadow
    radius: 8
    color: Theme.bgSolid
  }
}
