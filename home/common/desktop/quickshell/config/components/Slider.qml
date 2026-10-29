import QtQuick
import qs.common
import qs.services

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
  // a value that moves on its own in steps (a song's position, ticked a few
  // times a second): glide through each step at an even pace so it reads as
  // one movement. Otherwise a step (the wheel, a key) eases in quickly.
  property bool continuous: false
  // set by the caller from `moved`; the slider never writes `value` itself
  signal moved(real value)

  implicitWidth: 120
  implicitHeight: 24
  opacity: enabled ? 1 : 0.5
  // the keyboard steps it with Left and Right (Home and End for the ends)
  activeFocusOnTab: enabled
  Keys.onPressed: e => {
    const span = to - from;
    let f;
    if (e.key === Qt.Key_Left)
      f = fraction - step / span;
    else if (e.key === Qt.Key_Right)
      f = fraction + step / span;
    else if (e.key === Qt.Key_Home)
      f = 0;
    else if (e.key === Qt.Key_End)
      f = 1;
    else
      return;
    e.accepted = true;
    moved(from + clamp(f) * span);
  }

  function clamp(v: real): real {
    return Math.max(0, Math.min(1, v));
  }

  readonly property real fraction: clamp((value - from) / (to - from))
  // the level drawn; eased here, not in pixels, so a resize is not animated
  property real eased: fraction
  readonly property real shown: area.pressed ? area.dragFraction : eased

  // the pointer's drag is followed at once
  Behavior on eased {
    enabled: !area.pressed
    NumberAnimation {
      duration: root.continuous ? Theme.ms(220) : Theme.fast
      easing.type: root.continuous ? Easing.Linear : Theme.easeOut
    }
  }

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
    // grows under the pointer: it can be taken
    scale: area.pressed ? 1.2 : area.containsMouse ? 1.1 : 1

    // the focus ring, round the handle
    Rectangle {
      anchors.centerIn: parent
      width: parent.width + 6
      height: width
      radius: width / 2
      color: "transparent"
      border.width: 2
      border.color: Theme.accent
      visible: root.activeFocus && Menus.keyboard
    }

    Behavior on scale {
      NumberAnimation {
        duration: Theme.fast
        easing.type: Theme.easeOut
      }
    }
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
