import QtQuick
import qs.common

// 6px accent trough with a 14px handle; the item is 24px tall so the
// handle is easy to grab (same geometry as the ags `scale`)
Item {
  id: root

  property real value: 0
  property real from: 0
  property real to: 1
  property real step: 0.05
  // muted: the level stays visible but drops out of the accent
  property bool dimmed: false
  // set by the caller from `moved`; the slider never writes `value` itself
  signal moved(real value)

  implicitWidth: 120
  implicitHeight: 24
  opacity: enabled ? 1 : 0.5

  function clamp(v: real): real {
    return Math.max(0, Math.min(1, v));
  }

  readonly property real fraction: clamp((value - from) / (to - from))
  readonly property real shown: area.pressed ? area.dragFraction : fraction

  Rectangle {
    id: trough
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width
    height: 6
    radius: 3
    color: Theme.accentActive

    Rectangle {
      width: handle.x + handle.width / 2
      height: parent.height
      radius: 3
      color: root.dimmed ? Theme.border : Theme.accent
    }
  }

  Rectangle {
    id: handle
    anchors.verticalCenter: parent.verticalCenter
    x: root.shown * (root.width - width)
    width: 14
    height: 14
    radius: 7
    color: area.pressed || area.containsMouse ? "#ffffff" : Theme.fgBright
  }

  MouseArea {
    id: area

    property real dragFraction: 0

    function update(mx: real) {
      dragFraction = root.clamp((mx - handle.width / 2) / (width - handle.width));
      root.moved(root.from + dragFraction * (root.to - root.from));
    }

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    preventStealing: true
    onPressed: e => update(e.x)
    onPositionChanged: e => {
      if (pressed)
        update(e.x);
    }
    onWheel: e => {
      const d = e.angleDelta.y > 0 ? root.step : -root.step;
      root.moved(root.from + root.clamp(root.fraction + d / (root.to - root.from)) * (root.to - root.from));
    }
  }
}
