import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.services

// per-app volume; the header row shows or hides the list (remembered)
Section {
  id: root

  readonly property bool shown: UiState.mixerShown

  padding: 6
  spacing: 6

  Clickable {
    Layout.fillWidth: true
    fill: true
    padX: 8
    padY: 6
    radius: Theme.radiusControl
    spacing: 8
    onClicked: UiState.mixerShown = !UiState.mixerShown

    Txt {
      text: "Applications"
      color: Theme.fgBright
      font.pixelSize: 13
      font.weight: Font.Medium
      Layout.fillWidth: true
    }

    Txt {
      text: Audio.streams.length === 0 ? "None playing" : Audio.streams.length === 1 ? "1 playing" : `${Audio.streams.length} playing`
      font.pixelSize: 12
    }

    Chevron {
      open: root.shown
      color: Theme.fgBright
      font.pixelSize: 16
    }
  }

  ColumnLayout {
    visible: root.shown && Audio.streams.length > 0
    spacing: 8
    Layout.leftMargin: 4
    Layout.rightMargin: 4
    Layout.bottomMargin: 4

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
  }

  Txt {
    visible: root.shown && Audio.streams.length === 0
    text: "Apps appear here while they play audio"
    font.pixelSize: 12
    Layout.leftMargin: 8
    Layout.bottomMargin: 6
  }
}
