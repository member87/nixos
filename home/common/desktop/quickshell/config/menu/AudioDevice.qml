import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.services

// the default output (or input) device: its volume, and a chevron that
// opens the list of devices to switch to
ColumnLayout {
  id: root

  property bool output: true
  readonly property var node: output ? Audio.sink : Audio.source
  readonly property var devices: output ? Audio.sinks : Audio.sources
  readonly property real volume: node?.audio?.volume ?? 0
  readonly property bool muted: node?.audio?.muted ?? false
  property bool picking: false

  spacing: 6
  Layout.fillWidth: true

  VolumeRow {
    glyph: root.output ? Icons.volume(Math.round(root.volume * 100), root.muted) : Icons.microphone(root.muted)
    title: root.node ? Audio.deviceName(root.node) : root.output ? "No output device" : "No input device"
    volume: root.volume
    muted: root.muted
    available: root.node !== null
    onMoved: v => Audio.setVolume(root.node, v)
    onIconClicked: Audio.toggleMute(root.node)

    Clickable {
      id: chooser

      visible: root.devices.length > 1
      radius: 5
      implicitWidth: 28
      implicitHeight: 28
      color: root.picking ? Theme.accentActive : "transparent"
      onClicked: root.picking = !root.picking

      Glyph {
        text: root.picking ? Icons.chevronUp : Icons.chevronDown
        color: Theme.fgBright
        font.pixelSize: 16
      }

      Tooltip {
        target: chooser
        hovered: chooser.containsMouse && !root.picking
        text: root.output ? "Choose output device" : "Choose input device"
      }
    }
  }

  DeviceList {
    visible: root.picking
    Layout.leftMargin: 36
    nodes: root.devices
    current: root.node
    onPicked: node => {
      if (root.output)
        Audio.setDefaultSink(node);
      else
        Audio.setDefaultSource(node);
      root.picking = false;
    }
  }
}
