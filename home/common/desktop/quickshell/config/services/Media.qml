pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
  // the player that is playing, else the first one; MPRIS players come in
  // no particular order, so a paused browser tab must not hide the music
  readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
}
