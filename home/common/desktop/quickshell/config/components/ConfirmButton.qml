import QtQuick
import qs.common

// An action that cannot be taken back, asked twice in place: the first
// click turns it red and asks ("Forget?"), a second within a few seconds
// does it, and otherwise it settles back. Shows `glyph` (an icon) or `text`
// until asked; `confirmed` fires on the second click.
Clickable {
  id: root

  property string text: ""
  property string glyph: ""
  property string question: "Sure?"
  property bool armed: false
  signal confirmed

  padX: armed || glyph === "" ? 10 : 0
  padY: 4
  implicitWidth: armed || glyph === "" ? label.implicitWidth + padX * 2 : 24
  implicitHeight: 24
  radius: Theme.radiusControl
  color: armed ? Theme.critical : glyph === "" ? Theme.accentActive : "transparent"
  hoverColor: armed ? Qt.lighter(Theme.critical, 1.12) : Qt.rgba(250 / 255, 189 / 255, 47 / 255, 0.3)
  pressColor: armed ? Qt.darker(Theme.critical, 1.1) : Qt.rgba(250 / 255, 189 / 255, 47 / 255, 0.4)
  onClicked: {
    if (armed) {
      armed = false;
      confirmed();
    } else {
      armed = true;
      settle.restart();
    }
  }

  // asked, then left alone: it settles back
  Timer {
    id: settle
    interval: 3000
    onTriggered: root.armed = false
  }

  Glyph {
    visible: !root.armed && root.glyph !== ""
    text: root.glyph
    color: Theme.fg
    font.pixelSize: 14
  }

  Txt {
    id: label
    visible: root.armed || root.glyph === ""
    text: root.armed ? root.question : root.text
    color: root.armed ? Theme.accentInk : Theme.fgBright
    font.pixelSize: 12
  }
}
