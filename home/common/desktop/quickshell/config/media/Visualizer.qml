import QtQuick
import Quickshell.Services.Pipewire
import qs.common

// Spotify's loudness as a row of bars, drawn from PipeWire's peak monitor on
// its stream alone (not a spectrum: PipeWire gives levels, not frequencies).
// Every 50ms the loudest peak since the last tick enters at the centre and
// the older ones move out to both sides, or with `fromStart` enters at the
// left edge and moves right. Levels are shown against their own recent
// average, so a mastered-loud song still visibly moves.
Item {
  id: root

  // Spotify's output stream, or null
  property PwNode node: null
  property bool running: false
  property int barWidth: 4
  property int barGap: 3
  property bool fromStart: false
  // bars across the width, as many as fit (odd, so one sits in the middle)
  readonly property int bars: Math.max(1, Math.floor(((width + barGap) / (barWidth + barGap) - 1) / 2) * 2 + 1)
  // how many readings are on screen at once
  readonly property int span: fromStart ? bars : (bars + 1) / 2

  // newest first
  property var levels: []
  property real loudest: 0
  property real average: 0

  PwObjectTracker {
    objects: root.node ? [root.node] : []
  }

  PwNodePeakMonitor {
    node: root.node
    enabled: root.running && root.node !== null
    // ~190 updates a second: only keep the loudest
    onPeakChanged: root.loudest = Math.max(root.loudest, peak)
  }

  Timer {
    interval: 50
    repeat: true
    running: root.running
    onTriggered: {
      const v = root.loudest;
      root.loudest = 0;
      // the first reading sets the average: from 0 every bar would clip
      root.average = root.average > 0 ? root.average + (v - root.average) * 0.06 : v;
      const level = v > 0.002 ? Math.max(0, Math.min(1, 0.3 + (v - root.average) * 4.5)) : 0;
      root.levels = [level, ...root.levels.slice(0, root.span - 1)];
    }
  }

  // silence when it stops, not a frozen frame
  onRunningChanged: {
    if (!running) {
      levels = [];
      average = 0;
    }
  }

  Row {
    x: root.fromStart ? 0 : Math.round((root.width - width) / 2)
    anchors.verticalCenter: parent.verticalCenter
    spacing: root.barGap

    Repeater {
      model: root.bars

      Rectangle {
        required property int index
        readonly property int age: root.fromStart ? index : Math.abs(index - (root.span - 1))

        anchors.verticalCenter: parent.verticalCenter
        width: root.barWidth
        height: Math.max(root.barWidth, (root.levels[age] ?? 0) * root.height * 0.85)
        radius: root.barWidth / 2
        color: Theme.accent
        // fainter toward the edges, and behind the lyrics throughout
        opacity: 0.16 * (1 - age / root.span * 0.75)

        Behavior on height {
          NumberAnimation {
            duration: 60
          }
        }
      }
    }
  }
}
