pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

// UPower's display device, read the same way by the bar and the menu
Singleton {
  id: root

  readonly property var device: UPower.displayDevice
  readonly property bool present: device?.isLaptopBattery ?? false
  readonly property int percent: Math.round((device?.percentage ?? 0) * 100)
  readonly property bool charging: device?.state === UPowerDeviceState.Charging
  readonly property bool full: device?.state === UPowerDeviceState.FullyCharged

  // "3 h 18 min left", "Charging, full in 40 min"; "" while UPower has no
  // estimate yet (it needs a few readings after the state changes)
  readonly property string estimate: {
    if (charging)
      return device.timeToFull > 0 ? `Charging, full in ${duration(device.timeToFull)}` : "";
    if (full)
      return "";
    return device?.timeToEmpty > 0 ? `${duration(device.timeToEmpty)} left` : "";
  }

  // the estimate, or the state when there is none
  readonly property string status: estimate !== "" ? estimate : charging ? "Charging" : full ? "Fully charged" : "On battery"

  function duration(seconds: real): string {
    const m = Math.round(seconds / 60);
    return m >= 60 ? `${Math.floor(m / 60)} h ${m % 60} min` : `${m} min`;
  }
}
