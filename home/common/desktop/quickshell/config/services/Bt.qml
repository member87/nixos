pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

Singleton {
  id: root

  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property bool powered: adapter?.enabled ?? false
  readonly property var devices: adapter ? adapter.devices.values : []
  readonly property var paired: devices.filter(d => d.paired || d.bonded).sort((a, b) => b.connected - a.connected || a.name.localeCompare(b.name))
  // unnamed devices show up as their address ("4C-87-5D-..."): noise in a list
  readonly property var nearby: devices.filter(d => !d.paired && !d.bonded && d.name !== "" && !/^([0-9A-F]{2}[-:]){5}[0-9A-F]{2}$/i.test(d.name)).sort((a, b) => a.name.localeCompare(b.name))
  readonly property var connected: devices.filter(d => d.connected)
  readonly property string label: connected.length > 0 ? connected[0].name : "Bluetooth"

  // the device being paired; once paired it is trusted (so it may reconnect
  // on its own later) and connected
  property var pairing: null

  function toggle() {
    if (adapter)
      adapter.enabled = !adapter.enabled;
  }

  function pairAndConnect(device: var) {
    pairing = device;
    device.pair();
  }

  function forget(device: var) {
    if (pairing === device)
      pairing = null;
    device.forget();
  }

  // trust + connect once `paired` turns true; a pairing attempt that is
  // rejected or cancelled simply never gets there and is dropped on timeout
  Connections {
    target: root.pairing
    ignoreUnknownSignals: true

    function onPairedChanged() {
      const d = root.pairing;
      if (!d.paired)
        return;
      root.pairing = null;
      d.trusted = true;
      d.connect();
    }
  }

  Timer {
    running: root.pairing !== null
    interval: 60000
    onTriggered: root.pairing = null
  }
}
