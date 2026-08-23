import { Accessor, createBinding } from "ags"
import Battery from "gi://AstalBattery"
import Network from "gi://AstalNetwork"
import Bluetooth from "gi://AstalBluetooth"
import Wp from "gi://AstalWp"
import Brightness from "gi://AstalBrightness"

export const battery = Battery.get_default()
export const network = Network.get_default()
export const bluetooth = Bluetooth.get_default()
export const wp = Wp.get_default()
export const brightness = Brightness.get_default()

export const batteryPercent = createBinding(battery, "percentage")((p) => Math.round(p * 100))
export const batteryCharging = createBinding(battery, "charging")
export const batteryPresent = createBinding(battery, "isPresent")
export const batteryStateText = createBinding(battery, "state")((s) => {
  switch (s) {
    case Battery.State.CHARGING:
      return "Charging"
    case Battery.State.DISCHARGING:
      return "Discharging"
    case Battery.State.FULLY_CHARGED:
      return "Full"
    default:
      return ""
  }
})

export const primaryConnection = createBinding(network, "primary")

// A wifi/wired device might not exist on every host this config runs on -
// fall back to constant, always-disconnected accessors rather than crashing.
export const wifiEnabled = network.wifi
  ? createBinding(network.wifi, "enabled")
  : new Accessor(() => false)
export const wifiSsid = network.wifi
  ? // ssid is null until AstalNetwork finishes its async init (and during
    // reassociations); a null pushed into a Gtk label crashes the whole bar
    createBinding(network.wifi, "ssid")((s) => s ?? "Not Connected")
  : new Accessor(() => "Not Connected")
export const wifiStrength = network.wifi
  ? createBinding(network.wifi, "strength")
  : new Accessor(() => 0)
export const wifiInternet = network.wifi
  ? createBinding(network.wifi, "internet")
  : new Accessor(() => Network.Internet.DISCONNECTED)
export const wiredInternet = network.wired
  ? createBinding(network.wired, "internet")
  : new Accessor(() => Network.Internet.DISCONNECTED)

export const bluetoothPowered = createBinding(bluetooth, "isPowered")
export const bluetoothConnected = createBinding(bluetooth, "isConnected")
export const bluetoothDeviceName = createBinding(bluetooth, "devices")(
  (devices) => devices.find((d) => d.connected)?.name ?? "No device",
)

export const speakerVolume = createBinding(wp.audio, "defaultSpeaker", "volume")
export const speakerMuted = createBinding(wp.audio, "defaultSpeaker", "mute")

export const screenBrightness = brightness.screen
  ? createBinding(brightness.screen, "brightness")
  : null
