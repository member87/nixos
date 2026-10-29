import QtQuick
import QtQuick.Layouts
import qs.services
import Quickshell.Widgets
import qs.common
import qs.components

// first MPRIS player: round cover art + "title – artist"; a hover opens the
// player with lyrics underneath. A new track fades the old one out and
// itself in, rather than swapping under the eye.
RowLayout {
  id: root

  readonly property var player: Media.player
  readonly property string title: player?.trackTitle ?? ""
  readonly property string artist: player?.trackArtist ?? ""
  readonly property string label: artist ? `${title} – ${artist}` : title
  // what is on screen: `label` once the old one has faded
  property string shown: label

  onLabelChanged: swap.restart()

  visible: player !== null
  spacing: 4

  SequentialAnimation {
    id: swap
    NumberAnimation {
      target: root
      property: "opacity"
      to: 0
      duration: Theme.ms(70)
      easing.type: Theme.easeIn
    }
    ScriptAction {
      script: root.shown = root.label
    }
    NumberAnimation {
      target: root
      property: "opacity"
      to: 1
      duration: Theme.base
      easing.type: Theme.easeOut
    }
  }

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
      // the cover often arrives after the title: it fades in when it does
      opacity: status === Image.Ready ? 1 : 0

      Behavior on opacity {
        NumberAnimation {
          duration: Theme.base
        }
      }
    }
  }

  Txt {
    text: root.shown
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
