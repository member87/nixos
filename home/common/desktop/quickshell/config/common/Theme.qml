pragma Singleton

import QtQuick
import Quickshell

// gruvbox palette carried over from the ags bar (style.scss)
Singleton {
  readonly property color bg: Qt.rgba(29 / 255, 32 / 255, 33 / 255, 0.8)
  // the bar as it shows: bg at 0.8 over the wallpaper strip behind it,
  // opaque. Popouts hung from the bar use it, so they meet it without a seam
  // and windows do not show through them
  readonly property color barOpaque: Qt.rgba((29 * 0.8 + 40 * 0.2) / 255, (32 * 0.8 + 40 * 0.2) / 255, (33 * 0.8 + 40 * 0.2) / 255, 1)
  readonly property color bgSolid: "#1d2021"
  readonly property color fg: "#bdae93"
  readonly property color fgBright: "#ebdbb2"
  readonly property color accent: "#fabd2f"
  readonly property color accentHover: Qt.rgba(250 / 255, 189 / 255, 47 / 255, 0.1)
  readonly property color accentActive: Qt.rgba(250 / 255, 189 / 255, 47 / 255, 0.2)
  readonly property color border: "#665c54"
  readonly property color critical: "#fb4934"
  readonly property color good: "#b8bb26"
  // privacy indicators: orange for the microphone (the window border's
  // gradient start), critical red for the screen
  readonly property color orange: "#fe8019"
  readonly property color sectionBg: Qt.rgba(60 / 255, 56 / 255, 54 / 255, 0.6)
  // the wallpaper: gruvbox bg0 crossed by five stripes, top to bottom
  readonly property color wallpaper: "#282828"
  readonly property list<color> stripes: ["#fb4934", "#b8bb26", "#fabd2f", "#83a598", "#8ec07c"]
  // text drawn on an accent fill
  readonly property color accentInk: "#1d2021"
  // swaync's switch colours
  readonly property color switchTrack: "#504945"

  readonly property string font: "FiraCode Nerd Font"

  readonly property int barHeight: 23
  readonly property int menuWidth: 350
}
