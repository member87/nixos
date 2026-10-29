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
  radius: Theme.radiusSection
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

    MediaControls {
      player: root.player
      size: 34
      Layout.topMargin: 4
    }
  }
}
