import QtQuick
import Quickshell.Io
import qs.common
import qs.components

// "3 notifications while you were away: Signal, Discord". Reads the bar's
// saved history (the lock is a separate process with no notification
// server), live while locked. App names only: the lock shows no content.
Txt {
  id: root

  required property real since
  property var entries: []
  readonly property var away: entries.filter(e => e.time >= since)
  readonly property var apps: [...new Set(away.map(e => e.appName || "Notification"))]

  visible: away.length > 0
  text: `${away.length} notification${away.length === 1 ? "" : "s"} while you were away: ${apps.join(", ")}`
  font.pixelSize: 14
  elide: Text.ElideRight

  FileView {
    path: Paths.notifications
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try {
        root.entries = JSON.parse(text());
      } catch (e) {}
    }
  }
}
