import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.common
import qs.components
import qs.services

// status icons; a click opens the system menu below them
Clickable {
  id: root

  required property string screenName
  readonly property var battery: UPower.displayDevice
  readonly property int batteryPercent: Math.round((battery?.percentage ?? 0) * 100)
  readonly property bool charging: battery?.state === UPowerDeviceState.Charging

  padX: 6
  padY: 2
  radius: 10
  spacing: 16
  // stays tinted while its menu is open
  color: Menus.screen === screenName ? Theme.accentHover : "transparent"
  onClicked: Menus.toggle(screenName, "main")

  Glyph {
    text: Icons.volume(Math.round(Audio.volume * 100), Audio.muted)
  }

  Glyph {
    text: Net.icon
  }

  Glyph {
    text: Bt.powered && Bt.connected.length > 0 ? Icons.bluetoothOn : Icons.bluetoothOff
  }

  Glyph {
    visible: Vpn.connected
    text: Icons.vpnLocked
  }

  Glyph {
    visible: Caffeine.active
    text: Icons.awake
  }

  RowLayout {
    visible: root.battery?.isLaptopBattery ?? false
    spacing: 4

    Glyph {
      text: Icons.battery(root.batteryPercent, root.charging)
      color: root.batteryPercent <= 10 ? Theme.critical : root.batteryPercent >= 100 ? Theme.good : Theme.accent
    }

    Txt {
      text: `${root.batteryPercent}%`
    }
  }
}
