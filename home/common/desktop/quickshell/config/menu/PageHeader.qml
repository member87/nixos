import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.services

// back to the main page, the page title, and an optional control on the right
RowLayout {
  id: root

  property string title: ""
  default property alias trailing: right.data

  spacing: 6

  Clickable {
    padX: 6
    padY: 4
    radius: 5
    spacing: 6
    onClicked: Menus.page = "main"

    Glyph {
      text: Icons.chevronLeft
      font.pixelSize: 18
    }

    Txt {
      text: root.title
      color: Theme.accent
      font.pixelSize: 15
      font.bold: true
    }
  }

  Item {
    Layout.fillWidth: true
  }

  RowLayout {
    id: right
    spacing: 8
    Layout.rightMargin: 4
  }
}
