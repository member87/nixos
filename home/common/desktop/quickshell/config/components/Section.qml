import QtQuick
import QtQuick.Layouts
import qs.common

// `.system-menu-section`: a tone step above the menu, radius 5, padding 10
Rectangle {
  id: root

  default property alias content: column.data
  property alias spacing: column.spacing
  property int padding: 10

  Layout.fillWidth: true
  implicitHeight: column.implicitHeight + padding * 2
  radius: 5
  color: Theme.sectionBg

  ColumnLayout {
    id: column
    anchors.fill: parent
    anchors.margins: root.padding
    spacing: 8
  }
}
