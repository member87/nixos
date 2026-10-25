import QtQuick
import QtQuick.Layouts
import qs.common

// "Gateway    192.168.1.1"
RowLayout {
  id: root

  property string key: ""
  property string value: ""

  visible: value !== ""
  spacing: 8

  Txt {
    text: root.key
    font.pixelSize: 12
    Layout.preferredWidth: 76
  }

  Txt {
    text: root.value
    color: Theme.fgBright
    font.pixelSize: 12
    elide: Text.ElideMiddle
    Layout.fillWidth: true
  }
}
