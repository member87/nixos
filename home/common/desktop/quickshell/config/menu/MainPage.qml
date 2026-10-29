import QtQuick
import QtQuick.Layouts
import qs.components

ColumnLayout {
  spacing: 10

  SessionActions {}

  // speakers and microphone together: one sound section
  Section {
    spacing: 10

    AudioDevice {
      output: true
    }

    AudioDevice {
      output: false
    }
  }

  AppMixer {}
  BrightnessControl {}
  BatteryStatus {}
  QuickToggles {}
  MediaPanel {}
}
