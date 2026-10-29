import QtQuick
import QtQuick.Layouts
import qs.common

// Previous, play/pause and next for an MPRIS player, the same wherever a
// player shows: play is an accent disc (as the focused workspace and today
// are), the skips round and quiet beside it. `size` is the disc's diameter.
// The new symbol grows in when playback starts or stops, whatever started it.
RowLayout {
  id: root

  required property var player
  property int size: 40
  readonly property int side: Math.round(size * 0.8)
  readonly property bool playing: player?.isPlaying ?? false

  spacing: Math.round(size * 0.1)

  onPlayingChanged: pop.restart()

  Clickable {
    implicitWidth: root.side
    implicitHeight: root.side
    radius: root.side / 2
    enabled: root.player?.canGoPrevious ?? false
    onClicked: root.player.previous()

    Glyph {
      text: Icons.mediaPrev
      font.pixelSize: Math.round(root.size * 0.45)
    }
  }

  Clickable {
    implicitWidth: root.size
    implicitHeight: root.size
    radius: root.size / 2
    color: Theme.accent
    hoverColor: Qt.lighter(Theme.accent, 1.12)
    pressColor: Qt.darker(Theme.accent, 1.1)
    enabled: root.player?.canTogglePlaying ?? false
    onClicked: root.player.togglePlaying()

    Glyph {
      id: playGlyph
      text: root.playing ? Icons.mediaPause : Icons.mediaPlay
      color: Theme.accentInk
      font.pixelSize: Math.round(root.size * 0.5)
      // outlines, so it stays sharp while it grows
      renderType: Text.QtRendering
    }
  }

  Clickable {
    implicitWidth: root.side
    implicitHeight: root.side
    radius: root.side / 2
    enabled: root.player?.canGoNext ?? false
    onClicked: root.player.next()

    Glyph {
      text: Icons.mediaNext
      font.pixelSize: Math.round(root.size * 0.45)
    }
  }

  NumberAnimation {
    id: pop
    target: playGlyph
    property: "scale"
    from: 0.6
    to: 1
    duration: Theme.base
    easing.type: Theme.easeOut
  }
}
