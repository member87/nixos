import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.services

// The running NixOS generation against main's head on GitHub, which the
// 05:00 upgrade installs (services/Updates.qml): up to date or not. Checked
// as the menu opens; a click opens the NixOS page with the details.
Clickable {
  Layout.fillWidth: true
  fill: true
  padX: 10
  padY: 10
  radius: Theme.radiusSection
  spacing: 10
  color: Theme.sectionBg
  onClicked: Menus.page = "nixos"

  Component.onCompleted: Updates.refresh()

  Glyph {
    text: Icons.nixos
    color: Updates.outOfDate ? Theme.accent : Theme.fg
    font.pixelSize: 18
    Layout.preferredWidth: 26
  }

  ColumnLayout {
    spacing: 0
    Layout.fillWidth: true

    Txt {
      text: "NixOS"
      color: Theme.fgBright
      font.pixelSize: 13
      font.weight: Font.Medium
    }

    Txt {
      font.pixelSize: 12
      color: Updates.outOfDate && Updates.error === "" ? Theme.accent : Theme.fg
      text: Updates.status
      elide: Text.ElideRight
      Layout.fillWidth: true
    }
  }

  Glyph {
    text: Icons.chevronRight
    color: Theme.fg
    font.pixelSize: 14
  }
}
