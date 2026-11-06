import QtQuick
import qs.common
import qs.components

// The music drawer's seek bar, laid along its floor: a 3px line, accent up
// to where the song is. Near it the line thickens, a knob shows at the
// playhead and the time under the pointer above it; a press or a drag
// seeks there, once per pause in the drag.
Item {
  id: root

  required property var player
  // where the rail is drawn, inside the item: clear of the rounded corners
  property int inset: 12
  readonly property real length: player?.lengthSupported ? player.length : 0
  readonly property bool canSeek: (player?.canSeek ?? false) && length > 0
  readonly property bool near: area.containsMouse || area.pressed
  readonly property bool dragging: area.pressed
  // the time being dragged to, while dragging
  readonly property real dragSeconds: area.fraction * length

  function clamp(v: real): real {
    return Math.max(0, Math.min(1, v));
  }

  function clock(seconds: real): string {
    const s = Math.max(0, Math.floor(seconds));
    return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
  }

  // the song's place, ticked a few times a second: glided through at an
  // even pace, as the Slider does
  property real played: length > 0 ? clamp((player?.position ?? 0) / length) : 0
  Behavior on played {
    enabled: !area.pressed
    NumberAnimation {
      duration: Theme.ms(220)
      easing.type: Easing.Linear
    }
  }
  readonly property real shown: area.pressed ? area.fraction : played

  visible: length > 0

  Timer {
    id: seek
    interval: 120
    onTriggered: {
      if (root.canSeek)
        root.player.position = root.dragSeconds;
    }
  }

  Rectangle {
    id: trough
    x: root.inset
    width: root.width - root.inset * 2
    height: root.near ? 5 : 3
    y: root.height - 4 - height
    radius: height / 2
    color: Theme.accentActive

    Behavior on height {
      NumberAnimation {
        duration: Theme.fast
        easing.type: Theme.easeOut
      }
    }

    Rectangle {
      width: Math.max(parent.height, root.shown * parent.width)
      height: parent.height
      radius: parent.radius
      color: Theme.accent
    }

    Rectangle {
      id: knob
      x: root.shown * parent.width - width / 2
      anchors.verticalCenter: parent.verticalCenter
      width: 12
      height: 12
      radius: 6
      color: area.pressed ? "#ffffff" : Theme.fgBright
      scale: root.near && root.canSeek ? 1 : 0
      opacity: scale

      Behavior on scale {
        NumberAnimation {
          duration: Theme.fast
          easing.type: Theme.easeOut
        }
      }
    }
  }

  // the time a press would go to (or, dragging, is going to)
  Rectangle {
    visible: root.near && root.canSeek
    x: Math.max(0, Math.min(root.width - width, root.inset + (area.pressed ? root.shown : area.hoverFraction) * trough.width - width / 2))
    y: trough.y - 6 - height
    width: tip.implicitWidth + 12
    height: tip.implicitHeight + 2
    radius: Theme.radiusControl
    color: Theme.bgSolid
    border.width: 1
    border.color: Theme.border

    Txt {
      id: tip
      anchors.centerIn: parent
      text: root.clock((area.pressed ? root.shown : area.hoverFraction) * root.length)
      color: Theme.fgBright
      font.pixelSize: 12
      font.features: {
        "tnum": 1,
        "cv11": 1
      }
    }
  }

  // a strip along the floor, taller than the line, so it is easy to find
  MouseArea {
    id: area

    property real fraction: 0
    property real hoverFraction: 0

    function at(mx: real): real {
      return root.clamp((mx - root.inset) / trough.width);
    }

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 14
    enabled: root.canSeek
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    preventStealing: true
    onPressed: e => {
      fraction = at(e.x);
      seek.restart();
    }
    onPositionChanged: e => {
      hoverFraction = at(e.x);
      if (pressed) {
        fraction = hoverFraction;
        seek.restart();
      }
    }
    onReleased: {
      seek.stop();
      if (root.canSeek)
        root.player.position = root.dragSeconds;
    }
  }
}
