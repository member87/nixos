import QtQuick
import Quickshell.Io

// addresses of a connected interface; Quickshell.Networking does not expose
// IP configuration, so ask nmcli (refreshed every 5s while the page is open)
// Invisible so it takes no slot in a layout.
Item {
  id: root

  visible: false

  required property string iface
  property string connection: ""
  property string ipv4: ""
  property string gateway: ""
  property string dns: ""
  property string ipv6: ""

  Process {
    id: proc
    command: ["nmcli", "-t", "-f", "GENERAL.CONNECTION,IP4.ADDRESS,IP4.GATEWAY,IP4.DNS,IP6.ADDRESS", "device", "show", root.iface]
    stdout: StdioCollector {
      onStreamFinished: {
        const f = {};
        for (const line of text.split("\n")) {
          const i = line.indexOf(":");
          if (i < 0)
            continue;
          const key = line.slice(0, i).replace(/\[\d+\]$/, "");
          const value = line.slice(i + 1).replace(/\\:/g, ":");
          if (!value)
            continue;
          if (!f[key])
            f[key] = [];
          f[key].push(value);
        }
        root.connection = f["GENERAL.CONNECTION"]?.[0] ?? "";
        root.ipv4 = f["IP4.ADDRESS"]?.[0] ?? "";
        root.gateway = f["IP4.GATEWAY"]?.[0] ?? "";
        root.dns = (f["IP4.DNS"] ?? []).join(", ");
        // first global address; link-local fe80:: is noise here
        root.ipv6 = (f["IP6.ADDRESS"] ?? []).find(a => !a.startsWith("fe80")) ?? "";
      }
    }
  }

  Timer {
    interval: 5000
    running: root.iface !== ""
    repeat: true
    triggeredOnStart: true
    onTriggered: proc.running = true
  }
}
