pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// screen backlight through brightnessctl (it goes through logind, no root
// needed). Hosts without a backlight (odin) report available: false.
Singleton {
  id: root

  property bool available: false
  property real value: 0
  property real pending: -1

  function refresh() {
    if (!query.running)
      query.running = true;
  }

  function set(v: real) {
    value = Math.max(0.01, Math.min(1, v));
    pending = value;
    if (!throttle.running)
      throttle.start();
  }

  Process {
    id: query
    running: true
    // -m: "device,class,current,percent%,max"
    command: ["brightnessctl", "-m", "-c", "backlight", "info"]
    stdout: StdioCollector {
      onStreamFinished: {
        const f = text.trim().split(",");
        if (f.length >= 5 && Number(f[4]) > 0) {
          root.available = true;
          if (root.pending < 0)
            root.value = Number(f[2]) / Number(f[4]);
        }
      }
    }
  }

  // a slider drag fires many changes; apply at most one every 50ms
  Timer {
    id: throttle
    interval: 50
    onTriggered: {
      Quickshell.execDetached(["brightnessctl", "-q", "-c", "backlight", "set", Math.round(root.pending * 100) + "%"]);
      root.pending = -1;
    }
  }
}
