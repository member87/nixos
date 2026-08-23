export function batteryIcon(percentage: number, charging: boolean): string {
  if (charging) return "󰂄"
  if (percentage >= 95) return "󰁹"
  if (percentage >= 85) return "󰂂"
  if (percentage >= 75) return "󰂁"
  if (percentage >= 65) return "󰂀"
  if (percentage >= 55) return "󰁿"
  if (percentage >= 45) return "󰁾"
  if (percentage >= 35) return "󰁽"
  if (percentage >= 25) return "󰁼"
  if (percentage >= 15) return "󰁻"
  if (percentage >= 5) return "󰁺"
  return "󱃍"
}

export function volumeIcon(volume: number, muted: boolean): string {
  if (muted || volume === 0) return "󰝟"
  if (volume < 30) return "󰕿"
  if (volume < 70) return "󰖀"
  return "󰕾"
}

export function wifiIcon(strength: number): string {
  if (strength >= 80) return "󰤨"
  if (strength >= 60) return "󰤥"
  if (strength >= 40) return "󰤢"
  if (strength >= 20) return "󰤟"
  return "󰤯"
}

export const ETHERNET_ICON = "󰈀"
export const WIFI_DISCONNECTED_ICON = "󰤭"
export const BLUETOOTH_ON_ICON = "󰂯"
export const BLUETOOTH_OFF_ICON = "󰂲"
export const VPN_LOCKED_ICON = "󰌾"
export const VPN_UNLOCKED_ICON = "󰌿"
export const BRIGHTNESS_ICON = "󰃞"
export const NOTIFICATION_ICON = "󰂚"
export const MEDIA_PREV_ICON = "󰒮"
export const MEDIA_PLAY_ICON = "󰐊"
export const MEDIA_PAUSE_ICON = "󰏤"
export const MEDIA_NEXT_ICON = "󰒭"
