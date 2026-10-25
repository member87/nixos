import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.services

// One app's notifications in the centre: its newest in full, the rest folded
// behind "N more", which opens them in place.
ColumnLayout {
  id: root

  required property string app
  required property var items
  property bool open: false
  signal toggled

  spacing: 6

  Repeater {
    model: root.open ? root.items : root.items.slice(0, 1)

    NotificationCard {
      required property var modelData

      entry: modelData
      color: Theme.sectionBg
      Layout.fillWidth: true
    }
  }

  RowLayout {
    visible: root.items.length > 1
    spacing: 8
    Layout.leftMargin: 6

    Clickable {
      padX: 8
      padY: 4
      radius: 5
      spacing: 6
      onClicked: root.toggled()

      Txt {
        text: root.open ? "Show less" : `${root.items.length - 1} more from ${root.app}`
        color: Theme.fgBright
        font.pixelSize: 12
      }

      Glyph {
        text: root.open ? Icons.chevronUp : Icons.chevronDown
        color: Theme.fg
        font.pixelSize: 14
      }
    }

    Item {
      Layout.fillWidth: true
    }

    Clickable {
      padX: 8
      padY: 4
      radius: 5
      onClicked: Notifs.dismissGroup(root.app)

      Txt {
        text: `Clear ${root.items.length}`
        font.pixelSize: 12
      }
    }
  }
}
