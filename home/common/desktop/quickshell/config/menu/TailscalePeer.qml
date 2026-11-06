import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.services

// a device on the tailnet: its address while online, when it was last seen
// otherwise; a click copies the address
Clickable {
  id: row

  required property var modelData
  property bool copied: false

  // "5 min ago", "3 h ago", "12 days ago"
  function ago(ms: real): string {
    if (!ms)
      return "offline";
    const min = Math.max(0, Math.round((Time.now.getTime() - ms) / 60000));
    if (min < 60)
      return `${min} min ago`;
    const h = Math.round(min / 60);
    if (h < 48)
      return `${h} h ago`;
    return `${Math.round(h / 24)} days ago`;
  }

  Layout.fillWidth: true
  Layout.leftMargin: -4
  fill: true
  padX: 4
  padY: 3
  radius: Theme.radiusControl
  spacing: 8
  enabled: modelData.ipv4 !== ""
  onClicked: {
    Tailscale.copy(modelData.ipv4);
    copied = true;
    settle.restart();
  }

  Timer {
    id: settle
    interval: 1500
    onTriggered: row.copied = false
  }

  Glyph {
    text: Icons.device(row.modelData.os)
    color: Theme.fg
    font.pixelSize: 14
    Layout.preferredWidth: 16
  }

  Txt {
    text: row.modelData.name
    // the exit node in use stands out
    color: row.modelData.id === Tailscale.exitNode?.id ? Theme.accent : row.modelData.online ? Theme.fgBright : Theme.fg
    font.pixelSize: 12
    elide: Text.ElideRight
    Layout.fillWidth: true
  }

  Txt {
    text: row.copied ? "Copied" : row.modelData.online ? row.modelData.ipv4 : row.ago(row.modelData.lastSeen)
    color: row.copied ? Theme.good : Theme.fg
    font.pixelSize: 12
  }

  Tooltip {
    target: row
    hovered: row.containsMouse && !row.copied
    text: `Copy ${row.modelData.ipv4}`
  }
}
