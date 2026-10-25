import QtQuick
import Quickshell
import qs.common

// the ags `tooltip`: dark, 1px border, radius 5, shown after a short hover
PopupWindow {
  id: root

  required property Item target
  property string text: ""
  property bool hovered: false

  anchor.item: target
  anchor.edges: Edges.Bottom
  anchor.gravity: Edges.Bottom
  anchor.margins.top: 4 - surface.shadow
  anchor.adjustment: PopupAdjustment.All

  visible: delay.ready && hovered && text !== ""
  implicitWidth: label.implicitWidth + 12 + surface.shadow * 2
  implicitHeight: label.implicitHeight + 8 + surface.shadow * 2
  color: "transparent"
  // purely informational: never catches the pointer
  mask: Region {}

  onHoveredChanged: {
    delay.ready = false;
    if (hovered)
      delay.restart();
  }

  Timer {
    id: delay
    property bool ready: false
    interval: 500
    onTriggered: ready = true
  }

  PopupSurface {
    id: surface
    shadow: 10
    radius: 5
    color: Qt.rgba(29 / 255, 32 / 255, 33 / 255, 0.9)
    borderWidth: 1
    borderColor: Theme.border

    Txt {
      id: label
      anchors.centerIn: parent
      text: root.text
      textFormat: Text.StyledText
      color: Theme.fgBright
      font.pixelSize: 13
    }
  }
}
