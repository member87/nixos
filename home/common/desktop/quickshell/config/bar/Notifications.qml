import QtQuick
import qs.common
import qs.components
import qs.services

// bell + count of notifications not yet dismissed; opens the notification
// centre. The bell is struck through while do-not-disturb is on.
Clickable {
  id: root

  required property string screenName

  padX: 6
  padY: 2
  radius: 10
  spacing: 4
  color: Menus.screen === screenName && Menus.page === "notifications" ? Theme.accentHover : "transparent"
  onClicked: Menus.toggle(screenName, "notifications")

  Glyph {
    text: UiState.doNotDisturb ? "\u{F009B}" : Icons.notification
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
