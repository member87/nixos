import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.services

// status icons; a click opens the system menu below them. Each names its
// state on hover, and the wheel over the speaker sets the volume.
Clickable {
  id: root

  required property string screenName

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
    visible: Battery.present
    spacing: 4

    StatusGlyph {
      text: Icons.battery(Battery.percent, Battery.charging)
      color: Battery.percent <= 10 ? Theme.critical : Battery.percent >= 100 ? Theme.good : Theme.accent
      tip: Battery.status
    }

    Txt {
      text: `${Battery.percent}%`
    }
  }
}
