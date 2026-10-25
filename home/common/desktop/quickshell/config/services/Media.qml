pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
  // only Spotify: browser tabs, Discord and other MPRIS players are ignored
  // by the bar and the menu's media panel
  readonly property var player: Mpris.players.values.find(p => p.dbusName.toLowerCase().includes("spotify")) ?? null
}
