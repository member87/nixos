import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.services

// devices to switch the default to, on an inset one tone step down; the
// current one is ticked. For output, cast devices on the network follow.
Rectangle {
  id: root

  property var nodes: []
  property var current: null
  // {name, model, ip}; empty for input
  property var casts: []
  property bool castsShown: false
  property bool searching: false
  property var castTarget: null
  signal picked(var node)
  signal castPicked(var device)

  Layout.fillWidth: true
  implicitHeight: column.implicitHeight + 8
  radius: 5
  color: Qt.rgba(29 / 255, 32 / 255, 33 / 255, 0.6)

  ColumnLayout {
    id: column
    anchors.fill: parent
    anchors.margins: 4
    spacing: 0

    Repeater {
      model: root.nodes

      Clickable {
        id: row

        required property var modelData
        readonly property bool isCurrent: modelData.id === root.current?.id

        Layout.fillWidth: true
        fill: true
        padX: 6
        padY: 6
        radius: 4
        spacing: 8
        onClicked: root.picked(modelData)

        Txt {
          text: Audio.deviceName(row.modelData)
          color: row.isCurrent ? Theme.accent : Theme.fgBright
          font.pixelSize: 12
          elide: Text.ElideRight
          Layout.fillWidth: true
        }

        Glyph {
          text: row.isCurrent ? Icons.check : ""
          font.pixelSize: 14
          Layout.preferredWidth: 14
        }
      }
    }

    Txt {
      visible: root.castsShown
      text: root.casts.length === 0 && root.searching ? "Cast · looking for devices…" : root.casts.length === 0 ? "Cast · no devices found" : "Cast"
      font.pixelSize: 12
      Layout.leftMargin: 6
      Layout.topMargin: 8
      Layout.bottomMargin: 2
    }

    Repeater {
      model: root.castsShown ? root.casts : []

      Clickable {
        id: cast

        required property var modelData
        readonly property bool isCurrent: modelData.ip === root.castTarget?.ip

        Layout.fillWidth: true
        fill: true
        padX: 6
        padY: 6
        radius: 4
        spacing: 8
        onClicked: root.castPicked(modelData)

        Glyph {
          text: cast.isCurrent ? "\u{F0119}" : "\u{F0118}"
          color: cast.isCurrent ? Theme.accent : Theme.fg
          font.pixelSize: 14
        }

        Txt {
          text: cast.modelData.name
          color: cast.isCurrent ? Theme.accent : Theme.fgBright
          font.pixelSize: 12
          elide: Text.ElideRight
          Layout.fillWidth: true
        }

        Glyph {
          text: cast.isCurrent ? Icons.check : ""
          font.pixelSize: 14
          Layout.preferredWidth: 14
        }
      }
    }
  }
}
