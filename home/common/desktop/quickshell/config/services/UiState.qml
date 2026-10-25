pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// UI choices that survive a restart (~/.local/state/quickshell/...)
Singleton {
  property alias mixerShown: adapter.mixerShown
  property alias doNotDisturb: adapter.doNotDisturb

  FileView {
    path: Quickshell.statePath("ui.json")
    // read before anything binds to the values, so the defaults below can
    // never be written over the saved ones
    blockLoading: true
    printErrors: false
    onAdapterUpdated: writeAdapter()
    onLoadFailed: error => {
      if (error === FileViewError.FileNotFound)
        writeAdapter();
    }

    JsonAdapter {
      id: adapter
      property bool mixerShown: false
      property bool doNotDisturb: false
    }
  }
}
