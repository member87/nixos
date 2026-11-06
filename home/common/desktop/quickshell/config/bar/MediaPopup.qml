import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.common
import qs.components
import qs.media
import qs.services

// Spotify under the bar's now-playing, as a wide, short ribbon so it covers
// as little of the window below as it can. Left to right: the cover; the
// track, the controls, its heart and the time; the synced lyrics over its
// loudness; and what plays next. The seek bar runs along the drawer's floor.
// Opens after a short hover on the bar's track and stays while the pointer
// is on either.
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

  component VRule: Rectangle {
    implicitWidth: 1
    Layout.fillHeight: true
    color: Theme.rule
  }

  visible: false
  panelWidth: 920
  panelHeight: 168

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

  // Up next is asked for while the drawer is out
  Binding {
    target: Spotify
    property: "watched"
    value: root.visible
  }

  // a passing pointer does not open it; leaving for a moment does not close it
  Timer {
    id: opening
    interval: 100
    onTriggered: root.open()
  }

  Timer {
    id: closing
    interval: 300
    onTriggered: root.close()
  }

  Item {
    anchors.fill: parent

    HoverHandler {
      id: inside
    }

    RowLayout {
      x: 16
      y: 16
      width: parent.width - 32
      height: parent.height - 32
      spacing: 12

      // the cover often arrives after the title: the music glyph holds its
      // place until it does
      ClippingRectangle {
        implicitWidth: 120
        implicitHeight: 120
        radius: Theme.radiusSection
        color: Theme.sectionBg

        Glyph {
          anchors.centerIn: parent
          visible: cover.status !== Image.Ready
          text: Icons.music
          color: Theme.fg
          font.pixelSize: 44
        }

        Image {
          id: cover
          anchors.fill: parent
          source: root.player?.trackArtUrl ?? ""
          sourceSize: Qt.size(240, 240)
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
          opacity: status === Image.Ready ? 1 : 0

          Behavior on opacity {
            NumberAnimation {
              duration: Theme.base
            }
          }
        }
      }

      VRule {}

      ColumnLayout {
        spacing: 0
        Layout.preferredWidth: 184
        Layout.maximumWidth: 184
        Layout.alignment: Qt.AlignVCenter

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

        RowLayout {
          spacing: 0
          Layout.fillWidth: true
          Layout.topMargin: 8

          MediaControls {
            player: root.player
            size: 36
          }

          Item {
            Layout.fillWidth: true
          }

          Heart {
            uri: Spotify.current
          }
        }

        Txt {
          visible: root.length > 0
          // while dragging along the floor, where it would go
          text: `${root.clock(rail.dragging ? rail.dragSeconds : root.player?.position ?? 0)} / ${root.clock(root.length)}`
          font.pixelSize: 12
          font.features: {
            "tnum": 1,
            "cv11": 1
          }
          Layout.topMargin: 4
        }
      }

      VRule {}

      // also keeps the player's position, and with it the time and the rail,
      // current
      LyricsView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        player: root.player
        active: root.visible
        textSize: 14
        context: 1
        contextLines: 1
        flushLeft: true
        barsFromStart: false
      }

      VRule {}

      UpNext {
        Layout.preferredWidth: 216
        Layout.maximumWidth: 216
        Layout.fillHeight: true
      }
    }

    SeekRail {
      id: rail
      anchors.fill: parent
      player: root.player
    }
  }
}
