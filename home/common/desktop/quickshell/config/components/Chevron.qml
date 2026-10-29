import QtQuick
import qs.common

// a fold's chevron: points down while folded and turns over as it unfolds,
// so the turn shows which way the content went
Glyph {
  id: root

  property bool open: false

  text: Icons.chevronDown
  rotation: open ? 180 : 0
  // drawn as outlines, so it stays clean while it turns
  renderType: Text.QtRendering

  Behavior on rotation {
    NumberAnimation {
      duration: Theme.base
      easing.type: Theme.easeOut
    }
  }
}
