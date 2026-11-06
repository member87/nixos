import QtQuick
import QtQuick.Layouts
import qs.components

// the default tab: the output and input devices, then whatever is playing
ColumnLayout {
  spacing: 10

  PageHeader {
    title: "Sound"
  }

  AudioDevice {
    output: true
  }

  AudioDevice {
    output: false
  }

  Rule {}

  AppMixer {}
  MediaPanel {}
}
