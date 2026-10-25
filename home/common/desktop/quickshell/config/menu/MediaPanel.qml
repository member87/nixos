import QtQuick
import QtQuick.Layouts
import qs.services
import Quickshell.Widgets
import qs.common
import qs.components

// now playing: full-bleed album art under a scrim, info and controls on top
ClippingRectangle {
  id: root

  readonly property var player: Media.player

  visible: player !== null
  Layout.fillWidth: true
  implicitHeight: Math.max(90, info.implicitHeight + 20)
  radius: 10
  color: Theme.sectionBg

  Image {
    anchors.fill: parent
    source: root.player?.trackArtUrl ?? ""
    sourceSize.width: root.width
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
  }

  // scrim for legibility over bright covers
  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.45)
  }

  ColumnLayout {
    id: info
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.margins: 10
    spacing: 4

    Txt {
      text: root.player?.trackTitle || "Unknown Track"
      color: Theme.accent
      font.pixelSize: 15
      font.bold: true
      elide: Text.ElideRight
      Layout.fillWidth: true
    }

    Txt {
      text: root.player?.trackArtist || "Unknown Artist"
      color: Theme.fgBright
      opacity: 0.9
      font.pixelSize: 13
      elide: Text.ElideRight
      Layout.fillWidth: true
    }

    RowLayout {
      spacing: 20

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

          padX: 12
          padY: 6
          radius: 8
          enabled: modelData.on
          onClicked: modelData.run()

          Glyph {
            text: control.modelData.icon
            font.pixelSize: 18
          }
        }
      }
    }
  }
}
