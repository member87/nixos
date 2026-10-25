import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.services

Section {
  visible: Brightness.available

  VolumeRow {
    glyph: Icons.brightness
    title: "Screen brightness"
    iconEnabled: false
    volume: Brightness.value
    onMoved: v => Brightness.set(v)
  }

  // swayosd's brightness keys change it behind our back
  Timer {
    interval: 2000
    running: Brightness.available
    repeat: true
    onTriggered: Brightness.refresh()
  }
}
