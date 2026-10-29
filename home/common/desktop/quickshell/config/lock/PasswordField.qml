import QtQuick
import qs.common
import qs.components

// Typed characters show as squares in the wallpaper's stripe colours, in
// order, so the field reads as a short run of the stripe being laid down.
Rectangle {
  id: root

  required property var ctx
  readonly property int maxDots: 24
  // a question whose answer may be shown (an OTP, not the password)
  readonly property bool visibleAnswer: ctx.state === "prompt" && ctx.echo

  implicitWidth: 380
  implicitHeight: 52
  radius: height / 2
  color: Theme.bgSolid
  // an edge that holds 3:1 against the wallpaper even before anything is
  // typed; the accent once something is, red on a wrong password
  border.width: 2
  border.color: ctx.state === "failed" ? Theme.critical : ctx.buffer !== "" ? Theme.accent : Qt.rgba(189 / 255, 174 / 255, 147 / 255, 0.6)

  Behavior on border.color {
    ColorAnimation {
      duration: Theme.ms(120)
    }
  }

  transform: Translate {
    id: nudge
  }

  Txt {
    anchors.centerIn: parent
    visible: root.ctx.buffer === "" && root.ctx.state !== "checking"
    text: root.ctx.state === "prompt" ? root.ctx.prompt : `Password for ${root.ctx.user}`
    color: Theme.fg
    font.pixelSize: 15
  }

  Txt {
    anchors.centerIn: parent
    visible: root.visibleAnswer
    text: root.ctx.buffer
    color: Theme.fgBright
    font.pixelSize: 17
  }

  Row {
    anchors.centerIn: parent
    visible: !root.visibleAnswer
    spacing: 6

    Repeater {
      model: Math.min(root.ctx.buffer.length, root.maxDots)

      Rectangle {
        id: dot

        required property int index

        width: 12
        height: 12
        radius: 3
        color: Theme.stripes[index % Theme.stripes.length]
        opacity: root.ctx.state === "checking" ? 0.5 : 1
        scale: 0

        Component.onCompleted: scale = 1

        Behavior on scale {
          NumberAnimation {
            duration: Theme.ms(110)
            easing.type: Easing.OutBack
          }
        }

        Behavior on opacity {
          NumberAnimation {
            duration: Theme.ms(160)
          }
        }
      }
    }
  }

  // Enter hint once there is something to submit
  Glyph {
    anchors.right: parent.right
    anchors.rightMargin: 18
    anchors.verticalCenter: parent.verticalCenter
    visible: root.ctx.buffer !== "" && root.ctx.state === "idle"
    text: "\u{F0311}"
    color: Theme.fg
    font.pixelSize: 18
  }

  SequentialAnimation {
    id: shake
    NumberAnimation {
      target: nudge
      property: "x"
      to: -16
      duration: Theme.ms(50)
    }
    NumberAnimation {
      target: nudge
      property: "x"
      to: 14
      duration: Theme.ms(70)
    }
    NumberAnimation {
      target: nudge
      property: "x"
      to: -8
      duration: Theme.ms(70)
    }
    NumberAnimation {
      target: nudge
      property: "x"
      to: 0
      duration: Theme.ms(60)
    }
  }

  Connections {
    target: root.ctx
    function onFailuresChanged() {
      shake.restart();
    }
  }
}
