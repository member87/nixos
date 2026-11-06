import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.services

// The backlight, the battery and the power profile where the host has them
// (thor; odin has none), keeping the screen awake, and under a rule the
// session actions.
ColumnLayout {
  spacing: 10

  PageHeader {
    title: "Power"
  }

  BrightnessControl {}
  BatteryStatus {}
  PowerProfileControl {}

  RowLayout {
    spacing: 8
    Layout.fillWidth: true

    Glyph {
      text: Caffeine.active ? Icons.awake : Icons.awakeOff
      color: Caffeine.active ? Theme.accent : Theme.fg
      font.pixelSize: 18
      horizontalAlignment: Text.AlignHCenter
      Layout.preferredWidth: 28
    }

    ColumnLayout {
      spacing: 0
      Layout.fillWidth: true

      Txt {
        text: "Keep awake"
        color: Theme.fgBright
        font.pixelSize: 12
        Layout.fillWidth: true
      }

      Txt {
        text: Caffeine.active ? "Keeping the screen awake" : "Off"
        font.pixelSize: 12
      }
    }

    Toggle {
      checked: Caffeine.active
      onToggled: Caffeine.toggle()
      Accessible.name: "Keep awake"
    }
  }

  Rule {}

  SessionActions {}
}
