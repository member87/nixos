pragma Singleton

import QtQuick
import Quickshell

// Material Design glyphs from FiraCode Nerd Font (same codepoints as the ags bar)
Singleton {
  readonly property string ethernet: "\u{F0200}"
  readonly property string wifiOff: "\u{F092D}"
  readonly property string wifiFull: "\u{F0928}"
  readonly property string bluetoothOn: "\u{F00AF}"
  readonly property string bluetoothOff: "\u{F00B2}"
  readonly property string bluetoothConnected: "\u{F00B1}"
  readonly property string vpnLocked: "\u{F033E}"
  readonly property string vpnUnlocked: "\u{F033F}"
  readonly property string brightness: "\u{F00DE}"
  readonly property string notification: "\u{F009A}"
  readonly property string mediaPrev: "\u{F04AE}"
  readonly property string mediaPlay: "\u{F040A}"
  readonly property string mediaPause: "\u{F03E4}"
  readonly property string mediaNext: "\u{F04AD}"
  readonly property string music: "\u{F075A}"
  readonly property string awake: "\u{F0176}"
  readonly property string awakeOff: "\u{F06CA}"
  readonly property string powerSaver: "\u{F032A}"
  readonly property string powerBalanced: "\u{F05D1}"
  readonly property string powerPerformance: "\u{F14DE}"
  readonly property string chevronDown: "\u{F0140}"
  readonly property string chevronUp: "\u{F0143}"
  readonly property string chevronLeft: "\u{F0141}"
  readonly property string chevronRight: "\u{F0142}"
  readonly property string check: "\u{F012C}"
  readonly property string refresh: "\u{F0450}"
  readonly property string close: "\u{F0156}"
  readonly property string app: "\u{F08C6}"

  function battery(percentage: int, charging: bool): string {
    if (charging) return "\u{F0084}";
    if (percentage >= 95) return "\u{F0079}";
    if (percentage >= 85) return "\u{F0082}";
    if (percentage >= 75) return "\u{F0081}";
    if (percentage >= 65) return "\u{F0080}";
    if (percentage >= 55) return "\u{F007F}";
    if (percentage >= 45) return "\u{F007E}";
    if (percentage >= 35) return "\u{F007D}";
    if (percentage >= 25) return "\u{F007C}";
    if (percentage >= 15) return "\u{F007B}";
    if (percentage >= 5) return "\u{F007A}";
    return "\u{F10CD}";
  }

  function volume(volume: int, muted: bool): string {
    if (muted || volume === 0) return "\u{F075F}";
    if (volume < 30) return "\u{F057F}";
    if (volume < 70) return "\u{F0580}";
    return "\u{F057E}";
  }

  function microphone(muted: bool): string {
    return muted ? "\u{F036D}" : "\u{F036C}";
  }

  // strength is 0..100
  function wifi(strength: int, secured: bool): string {
    if (secured) {
      if (strength >= 80) return "\u{F092A}";
      if (strength >= 60) return "\u{F0927}";
      if (strength >= 40) return "\u{F0924}";
      if (strength >= 20) return "\u{F0921}";
      return "\u{F092C}";
    }
    if (strength >= 80) return "\u{F0928}";
    if (strength >= 60) return "\u{F0925}";
    if (strength >= 40) return "\u{F0922}";
    if (strength >= 20) return "\u{F091F}";
    return "\u{F092F}";
  }

  // BlueZ reports freedesktop icon names ("audio-headset", "input-mouse", ...)
  function bluetoothDevice(icon: string): string {
    if (icon.startsWith("audio-head")) return "\u{F02CB}";
    if (icon.startsWith("audio")) return "\u{F04C3}";
    if (icon === "input-mouse") return "\u{F037D}";
    if (icon === "input-keyboard") return "\u{F030C}";
    if (icon === "input-gaming") return "\u{F0297}";
    if (icon === "phone") return "\u{F011C}";
    if (icon === "computer") return "\u{F0322}";
    return "\u{F00AF}";
  }
}
