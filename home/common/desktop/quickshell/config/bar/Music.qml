import QtQuick
import QtQuick.Layouts
import qs.services
import Quickshell.Widgets
import qs.common
import qs.components

// first MPRIS player: round cover art + "title - artist"; a hover opens the
// player with lyrics underneath
RowLayout {
  id: root

  readonly property var player: Media.player
  readonly property string title: player?.trackTitle ?? ""
  readonly property string artist: player?.trackArtist ?? ""

  visible: player !== null
  spacing: 4

  ClippingRectangle {
    implicitWidth: 20
    implicitHeight: 20
    radius: 10
    color: Qt.rgba(0, 0, 0, 0.3)

    Image {
      anchors.fill: parent
      source: root.player?.trackArtUrl ?? ""
      sourceSize: Qt.size(40, 40)
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
    }
  }

  Txt {
    text: root.artist ? `${root.title} - ${root.artist}` : root.title
    elide: Text.ElideRight
    // GTK maxWidthChars: 40
    Layout.maximumWidth: metrics.advanceWidth

    TextMetrics {
      id: metrics
      font.family: Theme.font
      font.pixelSize: 14
      text: "0".repeat(40)
    }
  }

  HoverHandler {
    id: hover
  }

  MediaPopup {
    target: root
    hovered: hover.hovered
  }
}
