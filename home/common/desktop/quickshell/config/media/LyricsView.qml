import QtQuick
import Quickshell.Services.Pipewire
import qs.common
import qs.components

// The synced lyrics of the playing track over Spotify's loudness: the sung
// line held in the middle, bright and full size, the lines either side
// smaller and dimmer. A line too long for the width wraps onto a second.
// Without synced lyrics, a note in their place over the bars.
Item {
  id: root

  required property var player
  // fetch, read the position and draw the bars only while on screen
  property bool active: false
  property int textSize: 15
  // lines shown above and below the sung one
  property int context: 1
  property int barWidth: 4
  property int barGap: 3
  // flush left, the bars running out from the left edge; centred otherwise
  property bool flushLeft: false

  readonly property bool playing: player?.isPlaying ?? false
  // one line's slot: the text's height and the space under it
  readonly property int pad: Math.round(textSize * 0.45)
  readonly property real lineHeight: Math.ceil(metrics.height) + pad
  // Spotify's output stream, for the bars
  readonly property PwNode stream: Pipewire.nodes.values.find(n => n.isStream && n.name.toLowerCase().includes("spotify")) ?? null

  // the lines shown, and a spare one for the sung line to wrap into
  implicitHeight: lineHeight * (2 * context + 2)

  FontMetrics {
    id: metrics
    font.family: Theme.font
    font.pixelSize: root.textSize
  }

  // MPRIS sends the position on seeks only; Quickshell works it out from the
  // time since, on asking
  Timer {
    interval: 200
    repeat: true
    running: root.active && root.playing
    onTriggered: root.player.positionChanged()
  }

  Lyrics {
    id: lyrics
    active: root.active
    title: root.player?.trackTitle ?? ""
    artist: root.player?.trackArtist ?? ""
    length: root.player?.lengthSupported ? root.player.length : 0
    position: root.player?.position ?? 0
  }

  Visualizer {
    anchors.fill: parent
    node: root.stream
    running: root.active && root.playing
    barWidth: root.barWidth
    barGap: root.barGap
    fromStart: root.flushLeft
  }

  ListView {
    id: list

    anchors.fill: parent
    visible: lyrics.status === "ready"
    clip: true
    interactive: false
    model: lyrics.lines
    currentIndex: Math.max(0, lyrics.current)
    // the sung line, however many lines it wraps to, in the middle. Its
    // height is reported by the line itself: read off `currentItem`, the
    // range would move the current item and the current item the range.
    property real sungHeight: root.lineHeight

    highlightRangeMode: ListView.StrictlyEnforceRange
    preferredHighlightBegin: (height - sungHeight) / 2
    preferredHighlightEnd: preferredHighlightBegin + sungHeight
    highlightMoveDuration: Theme.ms(280)

    delegate: Item {
      id: line

      required property var modelData
      required property int index
      readonly property bool sung: index === lyrics.current
      // the lines still to come are the ones read ahead: brighter than the sung ones gone
      readonly property bool ahead: index > lyrics.current
      // the lines past the context are faded out, not cut at the edge
      readonly property bool near: Math.abs(index - list.currentIndex) <= root.context

      width: ListView.view.width
      height: label.implicitHeight + root.pad

      function report() {
        if (sung)
          list.sungHeight = height;
      }
      onSungChanged: report()
      onHeightChanged: report()
      Component.onCompleted: report()

      Txt {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        horizontalAlignment: root.flushLeft ? Text.AlignLeft : Text.AlignHCenter
        transformOrigin: root.flushLeft ? Item.Left : Item.Center
        text: line.modelData.text
        wrapMode: Text.WordWrap
        maximumLineCount: 2
        elide: Text.ElideRight
        color: line.sung || line.ahead ? Theme.fgBright : Theme.fg
        font.pixelSize: root.textSize
        font.weight: line.sung ? Font.Bold : Font.Normal
        // drawn as outlines, so the scaled lines stay sharp
        renderType: Text.QtRendering
        // scaled, not resized: the lines keep their place while one grows
        scale: line.sung ? 1 : 0.9
        opacity: !line.near ? 0 : line.sung ? 1 : line.ahead ? 0.8 : 0.5

        Behavior on scale {
          NumberAnimation {
            duration: Theme.ms(200)
            easing.type: Easing.OutCubic
          }
        }

        Behavior on opacity {
          NumberAnimation {
            duration: Theme.ms(200)
          }
        }
      }
    }
  }

  Txt {
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenter: root.flushLeft ? undefined : parent.horizontalCenter
    visible: lyrics.status !== "ready"
    text: lyrics.status === "none" ? "No synced lyrics for this track" : lyrics.status === "error" ? "Could not reach LRCLIB for lyrics" : "Finding lyrics…"
    font.pixelSize: Math.round(root.textSize * 0.86)
  }
}
