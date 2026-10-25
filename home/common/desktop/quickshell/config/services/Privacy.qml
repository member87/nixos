pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire

// What is watching or listening:
// - the screen: Hyprland announces every screencast start and stop; the
//   apps receiving it are the PipeWire consumers of the portal's video stream
// - the microphone: programs whose input streams are linked to a hardware
//   source (an app recording another app's output, or a sink monitor, is
//   not the microphone and is left out)
Singleton {
  id: root

  // Hyprland reports grim's single-frame screenshots as casts too; only a
  // cast that lasts past this is shown
  readonly property int settle: 1000

  property bool casting: false
  // "monitor" or "window", and its name (v2 events)
  property string castKind: ""
  property string castTarget: ""

  readonly property var groups: Pipewire.linkGroups.values

  readonly property var micStreams: unique(groups.filter(g => isRecording(g.target) && isHardwareSource(g.source)).map(g => g.target))
  readonly property var micApps: [...new Set(micStreams.map(n => Audio.appName(n)))]
  readonly property bool micInUse: micStreams.length > 0

  readonly property var castStreams: unique(groups.filter(g => g.source?.type === PwNodeType.VideoSource && g.target?.isStream).map(g => g.target))
  readonly property var castApps: [...new Set(castStreams.map(n => Audio.appName(n)))]
  // a portal stream with a consumer also means sharing (covers a bar
  // started mid-cast, which never saw Hyprland's start event)
  readonly property bool screenShared: casting || castStreams.length > 0

  function isRecording(n: var): bool {
    return n !== null && n.audio !== null && n.isStream && !n.isSink;
  }

  function isHardwareSource(n: var): bool {
    return n !== null && n.audio !== null && !n.isStream && !n.isSink;
  }

  function unique(nodes: var): var {
    const seen = new Set();
    return nodes.filter(n => !seen.has(n.id) && seen.add(n.id));
  }

  Connections {
    target: Hyprland

    // "screencast>>STATE,OWNER" and "screencastv2>>STATE,OWNER,NAME"
    function onRawEvent(event) {
      if (event.name !== "screencast" && event.name !== "screencastv2")
        return;
      const [state, kind, ...name] = event.data.split(",");
      if (state === "1") {
        if (event.name === "screencastv2") {
          root.castKind = kind;
          root.castTarget = name.join(",");
        }
        settleTimer.restart();
      } else {
        settleTimer.stop();
        root.casting = false;
      }
    }
  }

  Timer {
    id: settleTimer
    interval: root.settle
    onTriggered: root.casting = true
  }

  // app names come from node properties, which need the nodes bound
  PwObjectTracker {
    objects: [...root.micStreams, ...root.castStreams]
  }
}
