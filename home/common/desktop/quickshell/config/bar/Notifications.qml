import QtQuick
import qs.common
import qs.components
import qs.services

// bell + unread count; opens the swaync panel
Clickable {
  padX: 6
  padY: 2
  radius: 10
  spacing: 4
  onClicked: Notifs.togglePanel()

  Glyph {
    text: Icons.notification
  }

  Rectangle {
    visible: Notifs.count > 0
    implicitWidth: Math.max(22, count.implicitWidth + 12)
    implicitHeight: 18
    radius: 9
    color: Theme.accent

    Txt {
      id: count
      anchors.centerIn: parent
      text: Notifs.count
      color: Theme.accentInk
      font.pixelSize: 10
    }
  }
}
