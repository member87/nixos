import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.common
import qs.components
import qs.media
import qs.services

// Spotify, as in the bar: the synced lyrics over its loudness, the bars
// running out from Tux's side, and under them the cover, the track, where
// it is in it, and the controls. With Spotify closed, a button that opens it.
ColumnLayout {
  id: root

  required property int size
  required property int titleSize
  required property int lyricSize
  required property real maxWidth
  // lyrics, position and bars only while the desktop is out
  property bool live: false

  readonly property var player: Media.player
  readonly property bool timed: (player?.positionSupported ?? false) && (player?.lengthSupported ?? false) && player.length > 0

  function clock(seconds: real): string {
    const s = Math.max(0, Math.floor(seconds));
    return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
  }

  spacing: Math.round(size * 0.3)

  // also keeps the player's position, and with it the progress, current
  LyricsView {
    visible: root.player !== null
    Layout.preferredWidth: Math.min(root.maxWidth, root.lyricSize * 32)
    player: root.player
    active: root.live && visible
    textSize: root.lyricSize
    context: 2
    flushLeft: true
    barWidth: 6
    barGap: 4
  }

  RowLayout {
    id: track
    spacing: Math.round(root.size * 0.18)

    ClippingRectangle {
      implicitWidth: root.size
      implicitHeight: root.size
      Layout.alignment: Qt.AlignBottom
      radius: 6
      color: Theme.sectionBg

      Image {
        anchors.fill: parent
        visible: root.player !== null
        source: root.player?.trackArtUrl ?? ""
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
      }

      Glyph {
        anchors.centerIn: parent
        visible: root.player === null
        text: Icons.music
        color: Theme.fg
        font.pixelSize: Math.round(root.size * 0.4)
      }
    }

    ColumnLayout {
      Layout.alignment: Qt.AlignBottom
      Layout.maximumWidth: root.maxWidth - root.size - track.spacing
      spacing: 6

      Txt {
        text: root.player ? root.player.trackTitle || "Unknown track" : "Nothing playing"
        color: Theme.fgBright
        font.pixelSize: root.titleSize
        font.weight: Font.Bold
        elide: Text.ElideRight
        Layout.fillWidth: true
      }

      Txt {
        text: root.player ? root.player.trackArtist || "Unknown artist" : "Spotify is closed"
        font.pixelSize: 15
        elide: Text.ElideRight
        Layout.fillWidth: true
      }

      RowLayout {
        visible: root.timed
        spacing: 12
        Layout.topMargin: 8

        Meter {
          implicitWidth: Math.min(280, root.maxWidth - root.size - track.spacing - 110)
          fraction: root.timed ? root.player.position / root.player.length : 0
        }

        Txt {
          text: root.timed ? `${root.clock(root.player.position)} / ${root.clock(root.player.length)}` : ""
          font.pixelSize: 13
          font.features: {
            "tnum": 1,
            "cv11": 1
          }
        }
      }

      RowLayout {
        visible: root.player !== null
        spacing: 4
        Layout.leftMargin: -10

        Repeater {
          model: [
            {
              icon: Icons.mediaPrev,
              run: () => root.player.previous(),
              on: root.player?.canGoPrevious ?? false
            },
            {
              icon: root.player?.isPlaying ? Icons.mediaPause : Icons.mediaPlay,
              run: () => root.player.togglePlaying(),
              on: root.player?.canTogglePlaying ?? false
            },
            {
              icon: Icons.mediaNext,
              run: () => root.player.next(),
              on: root.player?.canGoNext ?? false
            }
          ]

          Clickable {
            id: control

            required property var modelData

            padX: 10
            padY: 6
            radius: 8
            enabled: modelData.on
            onClicked: modelData.run()

            Glyph {
              text: control.modelData.icon
              font.pixelSize: 22
            }
          }
        }
      }

      TextButton {
        visible: root.player === null
        text: "Open Spotify"
        primary: true
        Layout.topMargin: 8
        onClicked: Quickshell.execDetached(["spotify"])
      }
    }
  }
}
