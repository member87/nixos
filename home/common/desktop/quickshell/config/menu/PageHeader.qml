import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components

// a tab's title, and an optional control on the right (a power switch)
RowLayout {
  id: root

  property string title: ""
  default property alias trailing: right.data

  spacing: 6
  Layout.minimumHeight: 24

  Txt {
    text: root.title
    color: Theme.fgBright
    font.pixelSize: 14
    font.bold: true
    Layout.leftMargin: 2
    Layout.fillWidth: true
  }

  RowLayout {
    id: right
    spacing: 8
    Layout.rightMargin: 2
  }
}
