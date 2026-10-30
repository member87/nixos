import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Widgets
import qs.common
import qs.components
import qs.services

// One screen of the lock: the wallpaper redrawn with the clock where Tux
// sits, the stripes as the status line, the password underneath.
Item {
  id: root

  required property var ctx
  // preview mode: Escape leaves instead of clearing the field
  property bool preview: false
  // the login screen offers restart and shut down
  property bool powerControls: false
  signal leave

  readonly property real band: Math.round(height * 0.0176)
  readonly property int clockSize: Math.round(height * 0.2)
  readonly property var battery: UPower.displayDevice
  readonly property var player: Media.player

  Rectangle {
    anchors.fill: parent
    color: Theme.wallpaper
  }

  // everything but the ground fades out on unlock
  Item {
    id: content
    anchors.fill: parent
    opacity: root.ctx.state === "unlocking" ? 0 : 1

    Behavior on opacity {
      NumberAnimation {
        duration: Theme.ms(240)
        easing.type: Easing.InCubic
      }
    }

    // the clock stands on the stripes, where Tux sits on the wallpaper. It
    // rises out of them as they draw in, and sinks back into them on unlock;
    // this strip, cut at their top edge, hides it while it is down
    Item {
      width: parent.width
      height: stripes.y
      clip: true

      RollingClock {
        id: clock
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height - height + Math.round(root.height * 0.012)
        size: root.clockSize
        transform: Translate {
          id: clockShift
          y: clock.height
        }
      }
    }

    // the hidden offset is a binding, and an animation leaves it in place:
    // pin the shift once it has played, or a later size change (the clock's
    // digits, the message line under the field) would hide it again
    SequentialAnimation {
      running: true
      PauseAnimation {
        duration: Theme.ms(190)
      }
      NumberAnimation {
        target: clockShift
        property: "y"
        to: 0
        duration: Theme.ms(600)
        easing.type: Theme.easeStage
      }
      ScriptAction {
        script: clockShift.y = 0
      }
    }

    NumberAnimation {
      running: root.ctx.state === "unlocking"
      target: clockShift
      property: "y"
      to: clock.height
      duration: Theme.ms(210)
      easing.type: Theme.easeIn
    }

    Stripes {
      id: stripes
      ctx: root.ctx
      band: root.band
      width: parent.width
      y: Math.round(root.height * 0.456)
    }

    // under the stripes: the date and the field drop out of their lower edge
    Item {
      y: stripes.y + stripes.height
      width: parent.width
      height: parent.height - y
      clip: true

      ColumnLayout {
        id: below
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(root.height * 0.045)
        spacing: 22
        transform: Translate {
          id: belowShift
          y: -(below.y + below.height)
        }

        Txt {
          Layout.alignment: Qt.AlignHCenter
          text: Qt.formatDateTime(Time.now, "dddd d MMMM")
          color: Theme.fgBright
          font.pixelSize: Math.round(Math.max(20, root.height * 0.022))
          font.weight: Font.Medium
        }

        PasswordField {
          Layout.alignment: Qt.AlignHCenter
          ctx: root.ctx
        }

        // one line, the most urgent thing first
        Txt {
          visible: text !== ""
          Layout.alignment: Qt.AlignHCenter
          font.pixelSize: 14
          text: {
            if (root.ctx.state === "failed" || root.ctx.message !== "")
              return root.ctx.message;
            if (root.ctx.state === "checking")
              return "Checking…";
            if (root.ctx.capsLock)
              return "Caps Lock is on";
            if (root.ctx.fingerprint)
              return "or touch the fingerprint sensor";
            return "";
          }
          color: root.ctx.state === "failed" ? Theme.critical : root.ctx.capsLock && root.ctx.state === "idle" ? Theme.accent : Theme.fg
        }

        // the lock only (the greeter has no history)
        AwayNotifications {
          visible: root.ctx.lockedAt !== undefined && away.length > 0
          since: root.ctx.lockedAt ?? 0
          Layout.alignment: Qt.AlignHCenter
          Layout.topMargin: 10
          Layout.maximumWidth: root.width * 0.6
        }
      }
    }

    // pinned when done, as the clock's above
    SequentialAnimation {
      running: true
      PauseAnimation {
        duration: Theme.ms(290)
      }
      NumberAnimation {
        target: belowShift
        property: "y"
        to: 0
        duration: Theme.stage
        easing.type: Theme.easeStage
      }
      ScriptAction {
        script: belowShift.y = 0
      }
    }

    NumberAnimation {
      running: root.ctx.state === "unlocking"
      target: belowShift
      property: "y"
      to: -(below.y + below.height)
      duration: Theme.ms(180)
      easing.type: Theme.easeIn
    }

    // now playing, bottom left: Spotify only, as in the bar
    RowLayout {
      visible: root.player !== null
      anchors.left: parent.left
      anchors.bottom: parent.bottom
      anchors.margins: 40
      spacing: 14

      ClippingRectangle {
        implicitWidth: 56
        implicitHeight: 56
        radius: 6
        color: Theme.bgSolid

        Image {
          anchors.fill: parent
          source: root.player?.trackArtUrl ?? ""
          sourceSize: Qt.size(112, 112)
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
        }
      }

      ColumnLayout {
        spacing: 2
        Layout.maximumWidth: 320

        Txt {
          text: root.player?.trackTitle || "Unknown Track"
          color: Theme.fgBright
          font.pixelSize: 15
          font.weight: Font.Medium
          elide: Text.ElideRight
          Layout.fillWidth: true
        }

        Txt {
          text: root.player?.trackArtist || "Unknown Artist"
          font.pixelSize: 13
          elide: Text.ElideRight
          Layout.fillWidth: true
        }
      }

      MediaControls {
        player: root.player
        size: 44
        Layout.leftMargin: 10
      }
    }

    // bottom right: battery (laptops); restart and shut down (login screen)
    RowLayout {
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.margins: 40
      height: 56
      spacing: 24

      RowLayout {
        id: batteryRow

        readonly property int percent: Math.round((root.battery?.percentage ?? 0) * 100)

        visible: root.battery?.isLaptopBattery ?? false
        spacing: 8

        Glyph {
          text: Icons.battery(batteryRow.percent, root.battery?.state === UPowerDeviceState.Charging)
          color: batteryRow.percent <= 10 ? Theme.critical : Theme.accent
          font.pixelSize: 20
        }

        Txt {
          text: `${batteryRow.percent}%`
          color: Theme.fgBright
          font.pixelSize: 15
        }
      }

      Repeater {
        model: root.powerControls ? [
          {
            label: "Restart",
            icon: "\u{F0709}",
            command: ["systemctl", "reboot"]
          },
          {
            label: "Shut down",
            icon: "\u{F0425}",
            command: ["systemctl", "poweroff"]
          }
        ] : []

        Clickable {
          id: power

          required property var modelData

          padX: 12
          padY: 8
          radius: 8
          spacing: 8
          // a preview runs in your own session: never power it off
          enabled: !root.ctx.preview
          onClicked: Quickshell.execDetached(modelData.command)

          Glyph {
            text: power.modelData.icon
            font.pixelSize: 18
          }

          Txt {
            text: power.modelData.label
            color: Theme.fgBright
            font.pixelSize: 15
          }
        }
      }
    }
  }

  // all typing lands here; the field only draws the state
  Item {
    anchors.fill: parent
    focus: true

    Component.onCompleted: forceActiveFocus()

    Keys.onPressed: e => {
      root.ctx.checkCaps();
      if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
        root.ctx.submit();
      } else if (e.key === Qt.Key_Escape) {
        if (root.preview)
          root.leave();
        else
          root.ctx.erase(true);
      } else if (e.key === Qt.Key_Backspace) {
        root.ctx.erase(e.modifiers & Qt.ControlModifier);
      } else if (e.key === Qt.Key_U && e.modifiers & Qt.ControlModifier) {
        root.ctx.erase(true);
      } else if (e.text !== "" && e.text.charCodeAt(0) >= 32) {
        root.ctx.type(e.text);
      }
      e.accepted = true;
    }
  }
}
