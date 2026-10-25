pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// ProtonVPN brings up a `proton0` interface; its IPv4 address means connected
Singleton {
  id: root

  property string ip: ""
  readonly property bool connected: ip !== ""

  Process {
    id: proc
    command: ["ip", "-o", "-4", "addr", "show", "proton0"]
    stdout: StdioCollector {
      onStreamFinished: {
        const m = text.match(/inet (\d+\.\d+\.\d+\.\d+)/);
        root.ip = m ? m[1] : "";
      }
    }
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: proc.running = true
  }
}
