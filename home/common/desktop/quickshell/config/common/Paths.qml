pragma Singleton

import QtQuick
import Quickshell

// files shared between the shells (bar, lock screen): Quickshell.statePath()
// is per shell, so these live at fixed places
Singleton {
  readonly property string state: `${Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"}/quickshell`
  // the notification history, written by the bar, read by the lock screen
  readonly property string notifications: `${state}/notifications.json`
}
