import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.common
import qs.components
import qs.media
import qs.services

// Spotify under the bar's now-playing: the cover, the track, the controls, a
// seek bar, and the synced lyrics over its loudness. Opens after a short
// hover on the bar's track and stays while the pointer is on either.
BarPopup {
  id: root

  // the pointer is on the bar's track
  property bool hovered: false

  readonly property var player: Media.player
  readonly property real length: player?.lengthSupported ? player.length : 0
  readonly property bool wanted: (hovered || inside.hovered) && player !== null

  function clock(seconds: real): string {
    const s = Math.max(0, Math.floor(seconds));
    return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
  }

  visible: false
  // wide enough for most lyric lines on one line
  panelWidth: 560
  panelHeight: body.implicitHeight + 32

  onWantedChanged: {
    if (wanted) {
      closing.stop();
      // back on it while it slides away: it comes back down
      if (visible)
        root.open();
      else
        opening.restart();
    } else {
      opening.stop();
      closing.restart();
    }
  }

  // a passing pointer does not open it; leaving for a moment does not close it
  Timer {
    id: opening
    interval: 250
    onTriggered: root.open()
  }

  Timer {
    id: closing
    interval: 300
    onTriggered: root.close()
  }

  // one seek per drag pause, not one per pointer move
  Timer {
    id: seek
    property real to: 0
    interval: 120
    onTriggered: {
      if (root.player?.canSeek)
        root.player.position = to;
    }
  }

  Item {
    anchors.fill: parent

    HoverHandler {
      id: inside
    }

    ColumnLayout {
      id: body
      x: 16
      y: 16
      width: parent.width - 32
      spacing: 14

      RowLayout {
        spacing: 14
        Layout.fillWidth: true

        ClippingRectangle {
          implicitWidth: 64
          implicitHeight: 64
          radius: 6
          color: Theme.sectionBg

          Image {
            anchors.fill: parent
            source: root.player?.trackArtUrl ?? ""
            sourceSize: Qt.size(128, 128)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
          }
        }

        ColumnLayout {
          spacing: 2
          Layout.fillWidth: true

          Txt {
            text: root.player?.trackTitle || "Unknown track"
            color: Theme.fgBright
            font.pixelSize: 15
            font.weight: Font.Bold
            elide: Text.ElideRight
            Layout.fillWidth: true
          }

          Txt {
            text: root.player?.trackArtist || "Unknown artist"
            font.pixelSize: 13
            elide: Text.ElideRight
            Layout.fillWidth: true
          }
        }

        MediaControls {
          player: root.player
          size: 40
        }
      }

      ColumnLayout {
        visible: root.length > 0
        spacing: 0
        Layout.fillWidth: true

        Slider {
          Layout.fillWidth: true
          continuous: true
          // the keyboard and the wheel skip five seconds
          step: 5
          value: root.player?.position ?? 0
          to: root.length
          enabled: root.player?.canSeek ?? false
          onMoved: v => {
            seek.to = v;
            seek.restart();
          }
        }

        RowLayout {
          Layout.fillWidth: true

          Txt {
            text: root.clock(root.player?.position ?? 0)
            font.pixelSize: 12
            font.features: {
              "tnum": 1,
              "cv11": 1
            }
            Layout.fillWidth: true
          }

          Txt {
            text: root.clock(root.length)
            font.pixelSize: 12
            font.features: {
              "tnum": 1,
              "cv11": 1
            }
          }
        }
      }

      // also keeps the player's position, and with it the seek bar, current
      LyricsView {
        Layout.fillWidth: true
        player: root.player
        active: root.visible
      }
    }
  }
}
