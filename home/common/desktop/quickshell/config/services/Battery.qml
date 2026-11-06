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
  readonly property bool discharging: device?.state === UPowerDeviceState.Discharging

  // UPower divides the energy by the battery's instantaneous power, read
  // every 30 s, so its estimate swings with each spike of load. The power
  // here is the energy actually moved over the last 10 minutes instead;
  // UPower's own figure fills the first 2 minutes after a state change.
  readonly property real windowMs: 10 * 60 * 1000
  readonly property real minSpanMs: 2 * 60 * 1000
  // { t: ms, e: Wh }, oldest first, since the state last changed
  property var samples: []
  // W; 0 until there are minSpanMs of samples
  property real averagePower: 0

  readonly property real power: averagePower > 0 ? averagePower : (device?.changeRate ?? 0)
  readonly property real secondsLeft: {
    if (power <= 0)
      return 0;
    if (charging)
      return (device.energyCapacity - device.energy) / power * 3600;
    if (discharging)
      return device.energy / power * 3600;
    return 0;
  }

  // "3 h 20 min left", "Charging, full in 40 min"; "" while there is no
  // power reading yet (UPower needs a few after the state changes)
  readonly property string estimate: {
    if (secondsLeft <= 0)
      return "";
    return charging ? `Charging, full in ${duration(secondsLeft)}` : `${duration(secondsLeft)} left`;
  }

  // the estimate, or the state when there is none
  readonly property string status: estimate !== "" ? estimate : charging ? "Charging" : full ? "Fully charged" : "On battery"

  // 5-minute steps above an hour: an estimate is not good to the minute
  function duration(seconds: real): string {
    const m = seconds >= 3600 ? Math.round(seconds / 300) * 5 : Math.round(seconds / 60);
    return m >= 60 ? `${Math.floor(m / 60)} h ${m % 60} min` : `${m} min`;
  }

  function sample(): void {
    if (!present || !(charging || discharging)) {
      samples = [];
      averagePower = 0;
      return;
    }
    const now = Date.now();
    // a gap longer than the timer's beat is a suspend: its slow drain
    // would read as light use
    const last = samples.length > 0 ? samples[samples.length - 1] : null;
    const kept = last && now - last.t < 3 * 60 * 1000 ? samples.filter(s => now - s.t <= windowMs) : [];
    kept.push({
      t: now,
      e: device.energy
    });
    samples = kept;
    const span = now - kept[0].t;
    averagePower = span >= minSpanMs ? Math.abs(device.energy - kept[0].e) / (span / 3600000) : 0;
  }

  Connections {
    target: root.device
    function onEnergyChanged() {
      root.sample();
    }
    function onStateChanged() {
      root.samples = [];
      root.sample();
    }
  }

  Timer {
    interval: 60 * 1000
    running: root.present
    repeat: true
    triggeredOnStart: true
    onTriggered: root.sample()
  }
}
