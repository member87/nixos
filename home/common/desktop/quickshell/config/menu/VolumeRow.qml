import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.common
import qs.components

// [icon] Output  name ..........  62  [extra]
//        ━━━━━━━━━━━●──────
// The name labels the slider, after its role where there is one (a device's
// output and input can share a name); the figure is the level. The icon
// toggles mute. Used for devices, apps and the backlight.
RowLayout {
  id: root

  property string glyph: ""
  // app icon path; the glyph replaces it while muted or when there is none
  property string image: ""
  property string title: ""
  // "Output" / "Input": what the device is to the computer
  property string role: ""
  property real volume: 0
  property bool muted: false
  property bool available: true
  // false: the icon is decoration only (brightness has nothing to mute)
  property bool iconEnabled: true
  signal moved(real value)
  signal iconClicked
  default property alias extra: trailing.data

  spacing: 8
  Layout.fillWidth: true

  Clickable {
    radius: Theme.radiusControl
    implicitWidth: 28
    implicitHeight: 28
    enabled: root.available && root.iconEnabled
    // a disabled Clickable dims itself; a decorative icon should not
    opacity: root.available ? 1 : 0.5
    onClicked: root.iconClicked()

    IconImage {
      visible: root.image !== "" && !root.muted
      implicitSize: 18
      source: root.image
    }

    Glyph {
      visible: root.image === "" || root.muted
      text: root.glyph
      color: root.muted ? Theme.fg : Theme.accent
      font.pixelSize: 18
    }
  }

  ColumnLayout {
    spacing: 0
    Layout.fillWidth: true

    RowLayout {
      spacing: 6
      Layout.fillWidth: true

      Txt {
        visible: root.role !== ""
        text: root.role
        font.pixelSize: 12
      }

      Txt {
        text: root.title
        color: root.muted ? Theme.fg : Theme.fgBright
        font.pixelSize: 12
        elide: Text.ElideRight
        Layout.fillWidth: true
      }

      // the level, as the OSD shows it; muted reads "off"
      Txt {
        visible: root.available
        text: root.muted ? "off" : Math.round(root.volume * 100)
        font.pixelSize: 12
        horizontalAlignment: Text.AlignRight
        Layout.preferredWidth: figure.advanceWidth

        TextMetrics {
          id: figure
          font.family: Theme.font
          font.pixelSize: 12
          text: "100"
        }
      }
    }

    Slider {
      Layout.fillWidth: true
      implicitHeight: 18
      enabled: root.available
      dimmed: root.muted
      value: root.volume
      onMoved: v => root.moved(v)
    }
  }

  RowLayout {
    id: trailing
    visible: children.length > 0
    spacing: 0
  }
}
