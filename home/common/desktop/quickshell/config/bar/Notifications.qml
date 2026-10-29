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

  Tooltip {
    target: root
    hovered: root.containsMouse && Menus.screen === ""
    text: {
      const n = Notifs.count === 0 ? "No notifications" : Notifs.count === 1 ? "1 notification" : `${Notifs.count} notifications`;
      return UiState.doNotDisturb ? `${n}, do not disturb is on` : n;
    }
  }

  Glyph {
    text: UiState.doNotDisturb ? "\u{F009B}" : Icons.notification
  }

  Rectangle {
    id: badge

    // the count as it stood; a rise pulses the badge
    property int last: Notifs.count

    visible: Notifs.count > 0
    implicitWidth: Math.max(22, count.implicitWidth + 12)
    implicitHeight: 18
    radius: 9
    color: Theme.accent

    Connections {
      target: Notifs

      function onCountChanged() {
        if (Notifs.count > badge.last)
          pulse.restart();
        badge.last = Notifs.count;
      }
    }

    SequentialAnimation {
      id: pulse
      NumberAnimation {
        target: badge
        property: "scale"
        to: 1.18
        duration: Theme.ms(70)
        easing.type: Theme.easeOut
      }
      NumberAnimation {
        target: badge
        property: "scale"
        to: 1
        duration: Theme.ms(200)
        easing.type: Theme.easeOut
      }
    }

    Txt {
      id: count
      anchors.centerIn: parent
      text: Notifs.count
      color: Theme.accentInk
      font.pixelSize: 10
    }
  }
}
