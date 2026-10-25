pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Keeps the machine awake while the inhibitor process lives:
// - "idle" is honoured by hypridle (ignore_systemd_inhibit defaults to false),
//   so its lock, dpms-off and suspend timeouts never fire;
// - "sleep" makes logind refuse suspend and hibernate requests.
// The lid switch is left alone, closing a laptop still suspends it.
Singleton {
  id: root

  readonly property bool active: inhibitor.running

  function toggle() {
    inhibitor.running = !inhibitor.running;
  }

  // `cat` blocks on our stdin pipe: when the process is stopped or the bar
  // exits the pipe closes, cat sees EOF and the inhibitor lock is released
  // (a `sleep infinity` child would be orphaned instead)
  Process {
    id: inhibitor
    stdinEnabled: true
    command: ["systemd-inhibit", "--what=idle:sleep", "--who=quickshell", "--why=Keep awake toggle in the bar", "--mode=block", "cat"]
  }
}
