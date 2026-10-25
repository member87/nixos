import QtQuick
import qs.common
import qs.components
import qs.services

// time and date; a click opens the calendar
Clickable {
  id: root

  padX: 6
  padY: 2
  radius: 10
  spacing: 8
  color: calendar.visible ? Theme.accentHover : "transparent"
  // the click that dismissed the calendar lands here too: keep it closed
  onClicked: calendar.visible = !calendar.visible && Date.now() - calendar.closedAt > 250

  Txt {
    text: Time.time
  }

  Txt {
    text: Time.shortDate
    color: Theme.fgBright
    font.weight: Font.Medium
  }

  Calendar {
    id: calendar
    target: root
  }
}
