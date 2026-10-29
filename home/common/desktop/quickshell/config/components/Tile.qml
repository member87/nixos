import QtQuick
import QtQuick.Layouts
import qs.common

// quick-toggle tile (`.menu-grid-item`): icon beside label and status;
// `active` tints it, `connected` fills it with the accent. Tiles that open a
// page show a chevron.
Clickable {
  id: root

  property string icon: ""
  property string label: ""
  property string status: ""
  property bool active: false
  property bool connected: false
  property bool opensPage: false
  // a status-only tile (VPN) does not react to the pointer
  property bool interactive: true

  readonly property color surfaceColor: connected ? Theme.accent : active ? Theme.accentActive : Theme.sectionBg

  Layout.fillWidth: true
  Layout.preferredWidth: 100
  acceptedButtons: Qt.LeftButton | Qt.RightButton
  cursorShape: interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
  activeFocusOnTab: interactive
  fill: true
  padX: 10
  padY: 10
  // inside a section, so a step less round than it
  radius: Theme.radiusControl + 2
  spacing: 10
  color: surfaceColor
  hoverColor: !interactive ? surfaceColor : connected ? Qt.lighter(Theme.accent, 1.12) : Theme.accentHover
  pressColor: !interactive ? surfaceColor : connected ? Qt.darker(Theme.accent, 1.1) : Theme.accentActive

  Glyph {
    text: root.icon
    color: root.connected ? Theme.accentInk : Theme.accent
    font.pixelSize: 22
    Layout.preferredWidth: 24
  }

  ColumnLayout {
    spacing: 2
    Layout.fillWidth: true

    Txt {
      text: root.label
      color: root.connected ? Theme.accentInk : Theme.fgBright
      font.pixelSize: 13
      font.weight: Font.Medium
      elide: Text.ElideRight
      Layout.fillWidth: true
    }

    Txt {
      text: root.status
      color: root.connected ? Theme.accentInk : Theme.fg
      font.pixelSize: 12
      elide: Text.ElideRight
      Layout.fillWidth: true
    }
  }

  Glyph {
    visible: root.opensPage
    text: Icons.chevronRight
    color: root.connected ? Theme.accentInk : Theme.fg
    font.pixelSize: 14
  }
}
