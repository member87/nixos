import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.common
import qs.components

// [icon] name .....................  [extra]
//        ━━━━━━━━━━━●──────
// The name labels the slider; the icon toggles mute. Used for devices and apps.
RowLayout {
  id: root

  property string glyph: ""
  // app icon path; the glyph replaces it while muted or when there is none
  property string image: ""
  property string title: ""
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
    radius: 5
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

    // muted shows in the icon and the greyed slider; no figure needed
    Txt {
      text: root.title
      color: root.muted ? Theme.fg : Theme.fgBright
      font.pixelSize: 12
      elide: Text.ElideRight
      Layout.fillWidth: true
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
