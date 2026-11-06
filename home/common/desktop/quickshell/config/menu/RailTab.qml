import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.services

// One of the system menu's tabs on the rail: its glyph reports the tab's
// state (volume, signal, Bluetooth), in the tab's stripe colour. The open
// tab's fill is the rail's marker, drawn behind in the same shape; on it
// the glyph is ink. Rounded on the left only, as the marker runs on into
// the page.
Clickable {
  id: root

  required property string tab
  required property string label
  required property color stripe
  property string glyph: ""
  // something in the tab wants a look (an update waiting)
  property bool flagged: false
  // the tab the menu shows (kept while it slides into the notification centre)
  property bool current: false

  implicitHeight: 34
  fill: true
  radius: Theme.radiusControl + 2
  background.topRightRadius: 0
  background.bottomRightRadius: 0
  hoverColor: current ? "transparent" : Qt.rgba(stripe.r, stripe.g, stripe.b, 0.15)
  pressColor: current ? "transparent" : Qt.rgba(stripe.r, stripe.g, stripe.b, 0.25)
  onClicked: Menus.page = tab

  Accessible.role: Accessible.PageTab
  Accessible.name: label

  Item {
    Layout.fillWidth: true
    Layout.fillHeight: true

    // Centred on its ink, not its advance: the nerd glyphs sit unevenly in
    // their cells (the speaker leans left, the snowflake right), so centred
    // cells read as a crooked column.
    TextMetrics {
      id: ink
      font: icon.font
      text: icon.text
    }

    Glyph {
      id: icon
      x: Math.round((parent.width - ink.tightBoundingRect.width) / 2 - ink.tightBoundingRect.x)
      y: Math.round((parent.height - ink.tightBoundingRect.height) / 2 - ink.tightBoundingRect.y - baselineOffset)
      horizontalAlignment: Text.AlignLeft
      text: root.glyph
      color: root.current ? Theme.accentInk : root.stripe
      font.pixelSize: 18

      Behavior on color {
        ColorAnimation {
          duration: Theme.base
        }
      }
    }
  }

  Rectangle {
    visible: root.flagged
    parent: root
    x: parent.width - width - 6
    y: 5
    width: 7
    height: 7
    radius: 3.5
    color: Theme.accent
    border.width: 2
    border.color: Theme.barOpaque
  }

  Tooltip {
    target: root
    hovered: root.containsMouse
    text: root.label
  }
}
