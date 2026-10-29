import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.services

// left click on Network / Bluetooth opens their page, right click toggles
// wifi / bluetooth power directly
Section {
  GridLayout {
    columns: 2
    rowSpacing: 10
    columnSpacing: 10
    Layout.fillWidth: true

    Tile {
      icon: Net.wiredActive ? Icons.ethernet : Net.wifi && Net.wifiEnabled ? Net.icon : Icons.wifiOff
      label: Net.label
      status: {
        if (Net.wiredActive)
          return "Connected";
        if (Net.wifiNetwork)
          return `${Net.strength}% signal`;
        if (Net.wifi)
          return Net.wifiEnabled ? "Not connected" : "Off";
        return "Not connected";
      }
      active: Net.wifi !== null && Net.wifiEnabled
      connected: Net.connected
      opensPage: true
      onClicked: e => {
        if (e?.button === Qt.RightButton && Net.wifi)
          Net.toggleWifi();
        else
          Menus.page = "network";
      }
    }

    Tile {
      icon: Bt.powered ? (Bt.connected.length > 0 ? Icons.bluetoothConnected : Icons.bluetoothOn) : Icons.bluetoothOff
      label: "Bluetooth"
      status: {
        if (!Bt.adapter)
          return "No adapter";
        if (!Bt.powered)
          return "Off";
        if (Bt.connected.length > 1)
          return `${Bt.connected.length} connected`;
        return Bt.connected.length === 1 ? Bt.connected[0].name : "On";
      }
      active: Bt.powered
      connected: Bt.connected.length > 0
      opensPage: true
      onClicked: e => {
        if (e?.button === Qt.RightButton)
          Bt.toggle();
        else
          Menus.page = "bluetooth";
      }
    }

    Tile {
      icon: Vpn.connected ? Icons.vpnLocked : Icons.vpnUnlocked
      label: "VPN"
      status: Vpn.connected ? Vpn.ip : "Off"
      connected: Vpn.connected
      interactive: false
    }

    Tile {
      icon: Caffeine.active ? Icons.awake : Icons.awakeOff
      label: "Keep awake"
      status: Caffeine.active ? "On" : "Off"
      connected: Caffeine.active
      onClicked: Caffeine.toggle()
    }
  }
}
