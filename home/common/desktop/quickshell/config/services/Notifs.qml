pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// swaync owns notifications; the bar only shows its count and opens its panel
Singleton {
  id: root

  property int count: 0

  function togglePanel() {
    Quickshell.execDetached(["swaync-client", "-t"]);
  }

  Process {
    id: sub
    running: true
    command: ["swaync-client", "--subscribe-waybar"]
    stdout: SplitParser {
      onRead: line => {
        try {
          root.count = Number(JSON.parse(line).text) || 0;
        } catch (e) {}
      }
    }
    // swaync restarting ends the subscription; resubscribe
    onExited: retry.start()
  }

  Timer {
    id: retry
    interval: 3000
    onTriggered: sub.running = true
  }
}
