import { createComputed, With } from "ags"
import Network from "gi://AstalNetwork"
import {
  batteryPercent,
  batteryCharging,
  batteryPresent,
  primaryConnection,
  wifiEnabled,
  wifiStrength,
  wiredInternet,
  bluetoothPowered,
  bluetoothConnected,
  speakerVolume,
  speakerMuted,
} from "../lib/system"
import { vpn } from "../lib/vpn"
import {
  batteryIcon,
  volumeIcon,
  wifiIcon,
  ETHERNET_ICON,
  WIFI_DISCONNECTED_ICON,
  BLUETOOTH_ON_ICON,
  BLUETOOTH_OFF_ICON,
  VPN_LOCKED_ICON,
} from "../lib/icons"
import SystemMenu from "./SystemMenu"

export default function Indicators() {
  const networkIcon = createComputed(() => {
    if (primaryConnection() === Network.Primary.WIRED && wiredInternet() === Network.Internet.CONNECTED)
      return ETHERNET_ICON
    if (primaryConnection() === Network.Primary.WIFI && wifiEnabled())
      return wifiIcon(wifiStrength())
    return WIFI_DISCONNECTED_ICON
  })

  const volumeIconText = createComputed(() =>
    volumeIcon(Math.round(speakerVolume() * 100), speakerMuted()),
  )

  const bluetoothIcon = createComputed(() =>
    bluetoothPowered() && bluetoothConnected() ? BLUETOOTH_ON_ICON : BLUETOOTH_OFF_ICON,
  )

  const batteryIconText = createComputed(() => batteryIcon(batteryPercent(), batteryCharging()))
  const batteryClasses = createComputed(() => {
    const p = batteryPercent()
    if (p <= 10) return ["icon", "battery-critical"]
    if (p >= 100) return ["icon", "battery-full"]
    return ["icon"]
  })

  return (
    <menubutton class="system-container">
      <box spacing={16}>
        <label class="icon" label={volumeIconText} />
        <label class="icon" label={networkIcon} />
        <label class="icon" label={bluetoothIcon} />
        <With value={vpn}>
          {(v) => v.connected && <label class="icon vpn-connected" label={VPN_LOCKED_ICON} />}
        </With>
        <With value={batteryPresent}>
          {(present) =>
            present && (
              <box spacing={4}>
                <label cssClasses={batteryClasses} label={batteryIconText} />
                <label class="percentage" label={batteryPercent((p) => `${p}%`)} />
              </box>
            )
          }
        </With>
      </box>
      <popover>
        <SystemMenu />
      </popover>
    </menubutton>
  )
}
