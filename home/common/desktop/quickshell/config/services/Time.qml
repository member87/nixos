pragma Singleton

import QtQuick
import Quickshell

Singleton {
  readonly property date now: clock.date
  readonly property string time: Qt.formatDateTime(now, "hh:mm")
  readonly property string shortDate: Qt.formatDateTime(now, "dd MMM")
  readonly property string fullDate: Qt.formatDateTime(now, "dd MMM yyyy")
  readonly property string day: Qt.formatDateTime(now, "dddd")

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }
}
