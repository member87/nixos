import QtQuick
import qs.common

// a small labelled action; `primary` is the one filled button in a row
Clickable {
  id: root

  property string text: ""
  property bool primary: false

  padX: 10
  padY: 4
  radius: Theme.radiusControl
  color: primary ? Theme.accent : Theme.accentActive
  hoverColor: primary ? Qt.lighter(Theme.accent, 1.12) : Qt.rgba(250 / 255, 189 / 255, 47 / 255, 0.3)
  pressColor: primary ? Qt.darker(Theme.accent, 1.1) : Qt.rgba(250 / 255, 189 / 255, 47 / 255, 0.4)

  Txt {
    text: root.text
    color: root.primary ? Theme.accentInk : Theme.fgBright
    font.pixelSize: 12
  }
}
