import QtQuick
import qs.common
import qs.components
import qs.services

// a status icon in the bar that says what it shows when the pointer rests
// on it; quiet while a menu is open beneath it
Glyph {
  id: root

  property string tip: ""

  HoverHandler {
    id: hover
  }

  Tooltip {
    target: root
    hovered: hover.hovered && Menus.screen === ""
    text: root.tip
  }
}
