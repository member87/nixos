import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.services

Rectangle {
  Layout.fillWidth: true
  implicitHeight: row.implicitHeight + 40
  radius: 10
  color: Theme.sectionBg

  RowLayout {
    id: row
    anchors.fill: parent
    anchors.margins: 20
    spacing: 0

    Txt {
      text: Time.time
      color: Theme.accent
      font.pixelSize: 42
      font.bold: true
      Layout.rightMargin: 20
    }

    ColumnLayout {
      spacing: 2
      Layout.leftMargin: 15
      Layout.topMargin: 8
      Layout.fillWidth: true

      Txt {
        text: Time.fullDate
        color: Theme.fgBright
        font.weight: Font.Medium
      }

      Txt {
        text: Time.day
        color: Theme.fgBright
        opacity: 0.9
      }
    }
  }
}
