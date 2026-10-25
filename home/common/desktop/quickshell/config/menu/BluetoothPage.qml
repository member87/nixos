import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.common
import qs.components
import qs.services

ColumnLayout {
  id: root

  spacing: 10

  // discovery fills the "Nearby" list; only while this page is open
  Component.onCompleted: {
    if (Bt.powered)
      Bt.adapter.discovering = true;
  }
  Component.onDestruction: {
    if (Bt.adapter?.discovering)
      Bt.adapter.discovering = false;
  }

  Connections {
    target: Bt.adapter
    ignoreUnknownSignals: true

    // `enabled` flips while the adapter is still powering up and BlueZ
    // rejects discovery then; wait for the Enabled state
    function onStateChanged() {
      if (Bt.adapter.state === BluetoothAdapterState.Enabled)
        Bt.adapter.discovering = true;
    }
  }

  PageHeader {
    title: "Bluetooth"

    Toggle {
      visible: Bt.adapter !== null
      checked: Bt.powered
      enabled: Bt.adapter?.state !== BluetoothAdapterState.Blocked
      onToggled: Bt.toggle()
    }
  }

  Section {
    visible: !Bt.powered

    Txt {
      font.pixelSize: 12
      text: {
        if (!Bt.adapter)
          return "No Bluetooth adapter found";
        if (Bt.adapter.state === BluetoothAdapterState.Blocked)
          return "Bluetooth is blocked (rfkill)";
        return "Bluetooth is off";
      }
    }
  }

  Section {
    visible: Bt.powered
    spacing: 2

    Txt {
      text: "My devices"
      color: Theme.fgBright
      font.pixelSize: 13
      font.weight: Font.Medium
      Layout.leftMargin: 6
      Layout.bottomMargin: 4
    }

    Txt {
      visible: Bt.paired.length === 0
      text: "No paired devices"
      font.pixelSize: 12
      Layout.leftMargin: 6
    }

    Repeater {
      model: Bt.paired

      BluetoothRow {}
    }
  }

  Section {
    visible: Bt.powered
    spacing: 2

    RowLayout {
      Layout.leftMargin: 6
      Layout.bottomMargin: 4

      Txt {
        text: "Nearby"
        color: Theme.fgBright
        font.pixelSize: 13
        font.weight: Font.Medium
        Layout.fillWidth: true
      }

      Txt {
        visible: Bt.adapter?.discovering ?? false
        text: "Scanning…"
        font.pixelSize: 12
      }

      Clickable {
        visible: !(Bt.adapter?.discovering ?? true)
        padX: 6
        padY: 2
        radius: 5
        onClicked: Bt.adapter.discovering = true

        Txt {
          text: "Scan"
          color: Theme.fgBright
          font.pixelSize: 12
        }
      }
    }

    Txt {
      visible: Bt.nearby.length === 0
      text: "Put a device in pairing mode to see it here"
      font.pixelSize: 12
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
      Layout.leftMargin: 6
    }

    Repeater {
      model: Bt.nearby

      BluetoothRow {}
    }
  }
}
