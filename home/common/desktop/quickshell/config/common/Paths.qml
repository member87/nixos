pragma Singleton

import QtQuick
import Quickshell

// files shared between the shells (bar, lock screen) or kept across their
// restarts: Quickshell.statePath() and cachePath() are per shell, so these
// live at fixed places
Singleton {
  readonly property string state: `${Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"}/quickshell`
  readonly property string cache: `${Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache"}/quickshell`
  // the notification history, written by the bar, read by the lock screen
  readonly property string notifications: `${state}/notifications.json`
  // lyrics looked up on LRCLIB, so a song played again needs no lookup
  readonly property string lyrics: `${cache}/lyrics.json`
}
