import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.common
import qs.components
import qs.services

// status icons; a click opens the system menu below them. Each names its
// state on hover, and the wheel over the speaker sets the volume.
Clickable {
  id: root

  required property string screenName
  readonly property var battery: UPower.displayDevice
  readonly property int batteryPercent: Math.round((battery?.percentage ?? 0) * 100)
  readonly property bool charging: battery?.state === UPowerDeviceState.Charging

  function duration(seconds: real): string {
    const m = Math.round(seconds / 60);
    return m >= 60 ? `${Math.floor(m / 60)} h ${m % 60} min` : `${m} min`;
  }

  padX: 6
  padY: 2
  radius: 10
  spacing: 16
  // stays tinted while its menu is open
  color: Menus.screen === screenName && Menus.page !== "notifications" ? Theme.accentHover : "transparent"
  onClicked: Menus.toggle(screenName, "main")

  StatusGlyph {
    text: Icons.volume(Math.round(Audio.volume * 100), Audio.muted)
    tip: Audio.sink ? (Audio.muted ? `${Audio.deviceName(Audio.sink)}: muted` : `${Audio.deviceName(Audio.sink)}: ${Math.round(Audio.volume * 100)}%`) : "No output device"

    // one notch, five percent; touchpads add up to a notch first
    WheelHandler {
      property real acc: 0

      acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
      onWheel: e => {
        acc += e.angleDelta.y;
        if (Math.abs(acc) < 120)
          return;
        Audio.setVolume(Audio.sink, Audio.volume + (acc > 0 ? 0.05 : -0.05));
        acc = 0;
      }
    }
  }

  StatusGlyph {
    text: Net.icon
    tip: {
      if (Net.wiredActive)
        return Net.wiredActive.linkSpeed > 0 ? `Ethernet: ${Net.wiredActive.linkSpeed} Mb/s` : "Ethernet: connected";
      if (Net.wifiNetwork)
        return `Wi-Fi: ${Net.wifiNetwork.name}, ${Net.strength}%`;
      return Net.wifi && !Net.wifiEnabled ? "Wi-Fi is off" : "Not connected";
    }
  }

  StatusGlyph {
    text: Bt.powered && Bt.connected.length > 0 ? Icons.bluetoothOn : Icons.bluetoothOff
    tip: {
      if (!Bt.adapter)
        return "No Bluetooth adapter";
      if (!Bt.powered)
        return "Bluetooth is off";
      if (Bt.connected.length === 0)
        return "Bluetooth: nothing connected";
      return `Bluetooth: ${Bt.connected.map(d => d.name).join(", ")}`;
    }
  }

  StatusGlyph {
    visible: Vpn.connected
    text: Icons.vpnLocked
    tip: `VPN: ${Vpn.ip}`
  }

  StatusGlyph {
    visible: Caffeine.active
    text: Icons.awake
    tip: "Keeping the screen awake"
  }

  StatusGlyph {
    visible: Cast.active
    text: "\u{F0119}"
    tip: Cast.target ? `Casting audio to ${Cast.target.name}` : "Casting audio"
  }

  // hosts without power-profiles-daemon (odin) have nothing to show
  StatusGlyph {
    visible: Power.available
    text: Power.icon
    tip: `Power profile: ${Power.label}`
  }

  RowLayout {
    visible: root.battery?.isLaptopBattery ?? false
    spacing: 4

    StatusGlyph {
      text: Icons.battery(root.batteryPercent, root.charging)
      color: root.batteryPercent <= 10 ? Theme.critical : root.batteryPercent >= 100 ? Theme.good : Theme.accent
      tip: {
        const b = root.battery;
        if (root.charging)
          return b?.timeToFull > 0 ? `Charging, full in ${root.duration(b.timeToFull)}` : "Charging";
        if (b?.state === UPowerDeviceState.FullyCharged)
          return "Fully charged";
        return b?.timeToEmpty > 0 ? `${root.duration(b.timeToEmpty)} left` : `${root.batteryPercent}%`;
      }
    }

    Txt {
      text: `${root.batteryPercent}%`
    }
  }
}
