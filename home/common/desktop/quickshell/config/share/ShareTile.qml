import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell.Wayland
import Quickshell.Widgets
import qs.common
import qs.components
import qs.services

// One thing that can be shared: a still of it, its name, and a line saying
// where it is. A click (or Enter, Space) shares it.
MouseArea {
  id: root

  // a screen or a window's Wayland toplevel; null draws `glyph` instead
  property var source: null
  property string title: ""
  property string detail: ""
  // an app's icon beside the title
  property string icon: ""
  property string glyph: Icons.app
  // the frame's shape; stills are letterboxed in it
  property real aspect: 16 / 10
  // a dashed selection drawn in the frame, for the region tile
  property bool dashed: false
  readonly property bool captured: still.hasContent
  signal chosen

  hoverEnabled: true
  cursorShape: Qt.PointingHandCursor
  activeFocusOnTab: true
  onClicked: chosen()
  Keys.onPressed: e => {
    // Qt walks the focus chain on Tab before KeyNav sees the key: the
    // ring has to be switched on here
    if (e.key === Qt.Key_Tab || e.key === Qt.Key_Backtab)
      Menus.keyboard = true;
    if (e.key !== Qt.Key_Return && e.key !== Qt.Key_Enter && e.key !== Qt.Key_Space)
      return;
    e.accepted = true;
    if (!e.isAutoRepeat)
      root.chosen();
  }
  implicitHeight: frame.height + 10 + labels.implicitHeight

  readonly property bool lit: containsMouse || (activeFocus && Menus.keyboard)

  ClippingRectangle {
    id: frame
    width: parent.width
    height: Math.round(width / root.aspect)
    radius: Theme.radiusSection
    color: Theme.sectionBg

    // one frame, taken as the picker opens
    ScreencopyView {
      id: still
      anchors.centerIn: parent
      width: implicitWidth
      height: implicitHeight
      constraintSize: Qt.size(frame.width, frame.height)
      captureSource: root.source
      live: false
      paintCursor: false
      opacity: hasContent ? 1 : 0

      Behavior on opacity {
        NumberAnimation {
          duration: Theme.base
          easing.type: Theme.easeOut
        }
      }
    }

    Shape {
      id: marquee
      visible: root.dashed
      anchors.centerIn: parent
      width: Math.round(parent.width * 0.52)
      height: Math.round(parent.height * 0.5)
      preferredRendererType: Shape.CurveRenderer

      ShapePath {
        strokeColor: root.lit ? Theme.accent : Theme.fg
        strokeWidth: 2
        strokeStyle: ShapePath.DashLine
        dashPattern: [3, 3]
        fillColor: root.lit ? Theme.accentHover : "transparent"
        startX: 1
        startY: 1
        PathLine {
          x: marquee.width - 1
          y: 1
        }
        PathLine {
          x: marquee.width - 1
          y: marquee.height - 1
        }
        PathLine {
          x: 1
          y: marquee.height - 1
        }
        PathLine {
          x: 1
          y: 1
        }
      }
    }

    // nothing to show (no capture yet, or none possible): the app, or the glyph
    IconImage {
      anchors.centerIn: parent
      visible: !still.hasContent && root.icon !== ""
      implicitSize: 40
      source: root.icon
    }

    Glyph {
      anchors.centerIn: parent
      visible: !still.hasContent && root.icon === "" && !root.dashed
      text: root.glyph
      font.pixelSize: 34
    }
  }

  // hover and keyboard focus draw the same ring; a press darkens the still
  Rectangle {
    anchors.fill: frame
    radius: frame.radius
    color: root.pressed ? Qt.rgba(0, 0, 0, 0.25) : "transparent"
    border.width: 2
    border.color: root.lit ? Theme.accent : Qt.rgba(102 / 255, 92 / 255, 84 / 255, 0.5)

    Behavior on border.color {
      ColorAnimation {
        duration: Theme.fast
      }
    }
  }

  ColumnLayout {
    id: labels
    anchors.top: frame.bottom
    anchors.topMargin: 10
    width: parent.width
    spacing: 2

    RowLayout {
      spacing: 6
      Layout.fillWidth: true

      IconImage {
        visible: root.icon !== ""
        implicitSize: 16
        source: root.icon
      }

      Txt {
        text: root.title
        color: root.lit ? Theme.accent : Theme.fgBright
        font.pixelSize: 13
        elide: Text.ElideRight
        Layout.fillWidth: true
      }
    }

    Txt {
      visible: text !== ""
      text: root.detail
      font.pixelSize: 12
      elide: Text.ElideRight
      Layout.fillWidth: true
    }
  }
}
