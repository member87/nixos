pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Chromecasts and Google speakers on the network, and casting this
// computer's audio to one of them (bar-cast, home/common/desktop/quickshell).
// While casting, the default output is a "Cast: <name>" device, so the
// output slider and per-app volumes work as usual.
Singleton {
  id: root

  // {name, model, ip}
  property var devices: []
  property bool searching: false
  // the device being cast to, or null
  property var target: null
  readonly property bool active: caster.running
  // what to switch to once a cast has wound down (picking a real output
  // while casting)
  property var after: null

  function discover() {
    if (!finder.running)
      finder.running = true;
  }

  function start(device: var) {
    if (caster.running) {
      // casting elsewhere: end that first, start this when it is gone
      after = () => start(device);
      caster.running = false;
      return;
    }
    target = device;
    caster.running = true;
  }

  function stop(then: var) {
    after = then ?? null;
    if (caster.running)
      caster.running = false;
    else
      settle();
  }

  function settle() {
    target = null;
    const next = after;
    after = null;
    if (next)
      next();
  }

  // the null sink bar-cast makes; listed as the cast device, not an output
  function isCastSink(node: var): bool {
    return node?.name === "bar_cast";
  }

  Process {
    id: finder

    property var found: []

    command: ["bar-cast", "discover"]
    onStarted: {
      found = [];
      root.searching = true;
    }
    stdout: SplitParser {
      onRead: line => {
        const [name, model, ip] = line.split("\t");
        if (ip)
          finder.found.push({
            name,
            model,
            ip
          });
      }
    }
    onExited: {
      root.devices = finder.found.sort((a, b) => a.name.localeCompare(b.name));
      root.searching = false;
    }
  }

  // stdin stays open while casting; closing it (stopping the process) makes
  // bar-cast stop the device and restore the previous output
  Process {
    id: caster
    stdinEnabled: true
    command: ["bar-cast", "start", root.target?.ip ?? "", root.target?.name ?? ""]
    onExited: root.settle()
  }
}
