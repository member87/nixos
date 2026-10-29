import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.common
import qs.components
import qs.services

// a paired device (connect / disconnect / forget) or a nearby one (pair)
RowLayout {
  id: row

  required property var modelData
  readonly property bool known: modelData.paired || modelData.bonded
  readonly property bool pairing: modelData.pairing || Bt.pairing === modelData
  readonly property bool busy: pairing || modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting

  spacing: 8
  Layout.fillWidth: true
  Layout.leftMargin: 6

  Glyph {
    text: Icons.bluetoothDevice(row.modelData.icon)
    color: row.modelData.connected ? Theme.accent : Theme.fg
    font.pixelSize: 16
    Layout.preferredWidth: 26
  }

  ColumnLayout {
    spacing: 0
    Layout.fillWidth: true

    Txt {
      text: row.modelData.name
      color: Theme.fgBright
      font.pixelSize: 12
      elide: Text.ElideRight
      Layout.fillWidth: true
    }

    Txt {
      font.pixelSize: 12
      text: {
        const d = row.modelData;
        if (row.pairing)
          return "Pairing…";
        if (d.state === BluetoothDeviceState.Connecting)
          return "Connecting…";
        if (d.state === BluetoothDeviceState.Disconnecting)
          return "Disconnecting…";
        if (d.connected)
          return d.batteryAvailable ? `Connected · battery ${Math.round(d.battery * 100)}%` : "Connected";
        return row.known ? "Not connected" : "Not paired";
      }
    }
  }

  TextButton {
    text: !row.known ? "Pair" : row.modelData.connected ? "Disconnect" : "Connect"
    enabled: !row.busy
    onClicked: {
      const d = row.modelData;
      if (!row.known)
        Bt.pairAndConnect(d);
      else if (d.connected)
        d.disconnect();
      else
        d.connect();
    }
  }

  // forgetting unpairs it: asked twice, since only re-pairing undoes it
  ConfirmButton {
    id: forgetButton

    visible: row.known
    glyph: Icons.close
    question: "Forget?"
    onConfirmed: Bt.forget(row.modelData)

    Tooltip {
      target: forgetButton
      hovered: forgetButton.containsMouse && !forgetButton.armed
      text: "Forget device"
    }
  }
}
