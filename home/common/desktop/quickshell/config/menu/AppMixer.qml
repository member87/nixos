import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.services

// per-app volume: one row for each app playing audio
ColumnLayout {
  spacing: 8
  Layout.fillWidth: true

  Repeater {
    model: Audio.streams

    VolumeRow {
      required property var modelData

      image: Audio.appIcon(modelData)
      glyph: muted ? Icons.volume(0, true) : Icons.app
      title: Audio.appName(modelData)
      volume: modelData.audio?.volume ?? 0
      muted: modelData.audio?.muted ?? false
      onMoved: v => Audio.setVolume(modelData, v)
      onIconClicked: Audio.toggleMute(modelData)

      // the device rows' chooser width, so all sliders end on one line
      Item {
        implicitWidth: 28
      }
    }
  }

  Txt {
    visible: Audio.streams.length === 0
    text: "Apps appear here while they play audio"
    font.pixelSize: 12
    Layout.leftMargin: 2
  }
}
