import QtQuick
import qs.common
import qs.services

// The big clock of the desktop and the lock: hh:mm in bold, each digit in
// its own slot. When a digit changes, the old one lifts away as the new one
// rises into its place, as the widgets rise out of the stripes; the digits
// that stay keep still. The font is monospaced, so slots never shift.
Item {
  id: root

  property int size: 96
  property color color: Theme.fgBright
  readonly property real letterSpacing: -size * 0.03
  // how far a digit travels on its way in or out
  readonly property real travel: Math.round(size * 0.32)

  implicitWidth: row.width
  implicitHeight: probe.implicitHeight
  baselineOffset: probe.baselineOffset

  // a digit's box and baseline, for the slots
  Txt {
    id: probe
    visible: false
    text: "0"
    font.pixelSize: root.size
    font.weight: Font.Bold
  }

  TextMetrics {
    id: metrics
    font: probe.font
    text: "0"
  }

  Row {
    id: row
    spacing: root.letterSpacing

    Repeater {
      // a count, so the slots last as long as the time keeps its length
      model: Time.time.length

      Item {
        id: slot

        required property int index
        readonly property string glyph: Time.time.charAt(index)
        property string current: glyph
        property string previous: ""

        width: metrics.advanceWidth
        height: probe.implicitHeight

        onGlyphChanged: {
          previous = current;
          current = glyph;
          roll.restart();
        }

        Txt {
          id: outgoing
          text: slot.previous
          color: root.color
          opacity: 0
          font.pixelSize: root.size
          font.weight: Font.Bold
          // FiraCode's slashed zero is for code; a clock wants the plain one
          font.features: {
            "cv11": 1
          }
          // outlines, so a digit in motion stays sharp
          renderType: Text.QtRendering
        }

        Txt {
          id: incoming
          text: slot.current
          color: root.color
          font.pixelSize: root.size
          font.weight: Font.Bold
          font.features: {
            "cv11": 1
          }
          renderType: Text.QtRendering
        }

        ParallelAnimation {
          id: roll
          NumberAnimation {
            target: outgoing
            property: "y"
            from: 0
            to: -root.travel
            duration: Theme.ms(290)
            easing.type: Theme.easeIn
          }
          NumberAnimation {
            target: outgoing
            property: "opacity"
            from: 1
            to: 0
            duration: Theme.ms(240)
            easing.type: Theme.easeIn
          }
          NumberAnimation {
            target: incoming
            property: "y"
            from: root.travel
            to: 0
            duration: Theme.stage
            easing.type: Theme.easeStage
          }
          NumberAnimation {
            target: incoming
            property: "opacity"
            from: 0
            to: 1
            duration: Theme.ms(340)
            easing.type: Theme.easeOut
          }
        }
      }
    }
  }
}
