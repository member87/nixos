pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.common

// power-profiles-daemon's three profiles (thor). Hosts without the daemon
// (odin) report available: false, and PowerProfiles is never touched there:
// its first use tries to start the daemon and warns when it can't.
Singleton {
  id: root

  property bool available: false
  // a PowerProfile value; Balanced until the daemon answers
  readonly property int profile: available ? PowerProfiles.profile : PowerProfile.Balanced
  readonly property bool hasPerformance: available && PowerProfiles.hasPerformanceProfile
  readonly property string icon: profile === PowerProfile.PowerSaver ? Icons.powerSaver : profile === PowerProfile.Performance ? Icons.powerPerformance : Icons.powerBalanced
  readonly property string label: profile === PowerProfile.PowerSaver ? "Power saver" : profile === PowerProfile.Performance ? "Performance" : "Balanced"

  readonly property var names: ({
      [PowerProfile.PowerSaver]: "power-saver",
      [PowerProfile.Balanced]: "balanced",
      [PowerProfile.Performance]: "performance"
    })

  // Quickshell itself refuses Performance while hasPerformanceProfile is false
  function set(p: int): void {
    if (available)
      PowerProfiles.profile = p;
  }

  // connect to the daemon as soon as it is known to exist, not on first use,
  // so its properties are loaded before a click or an IPC call
  onAvailableChanged: if (available)
    PowerProfiles.profile;

  // "power-saver" | "balanced" | "performance", as powerprofilesctl names them
  function setByName(name: string): bool {
    for (const p of [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]) {
      if (names[p] === name) {
        set(p);
        return true;
      }
    }
    return false;
  }

  function cycle(): void {
    const order = hasPerformance ? [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance] : [PowerProfile.PowerSaver, PowerProfile.Balanced];
    set(order[(order.indexOf(profile) + 1) % order.length]);
  }

  // the daemon's bus name, running or activatable
  Process {
    running: true
    command: ["busctl", "--system", "list", "--no-legend", "--no-pager"]
    stdout: StdioCollector {
      onStreamFinished: root.available = text.split("\n").some(l => l.split(/\s+/)[0] === "org.freedesktop.UPower.PowerProfiles")
    }
  }
}
