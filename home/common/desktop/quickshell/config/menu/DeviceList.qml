import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.services

// devices to switch the default to, on an inset one tone step down; the
// current one is ticked
Rectangle {
  id: root

  property var nodes: []
  property var current: null
  signal picked(var node)

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
  }
}
