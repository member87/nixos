import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common
import qs.components
import qs.services

// Lock, suspend, log out, restart, shut down: labelled buttons at the foot
// of the Power tab, shut down alone on the last row. The three that end the
// session ask first, in place: one click turns the button red and a line
// under them says what a second click will do; left alone, it settles.
ColumnLayout {
  id: root

  // the action asked about, or ""
  property string armed: ""

  readonly property var actions: [
    {
      id: "lock",
      label: "Lock",
      icon: "\u{F033E}",
      command: ["loginctl", "lock-session"],
      ask: false
    },
    {
      id: "suspend",
      label: "Suspend",
      icon: "\u{F0904}",
      command: ["systemctl", "suspend"],
      ask: false
    },
    {
      id: "logout",
      label: "Log out",
      icon: "\u{F0343}",
      command: ["hyprctl", "dispatch", "hl.dsp.exit()"],
      ask: true
    },
    {
      id: "reboot",
      label: "Restart",
      icon: "\u{F0709}",
      command: ["systemctl", "reboot"],
      ask: true
    },
    {
      id: "poweroff",
      label: "Shut down",
      icon: Icons.power,
      command: ["systemctl", "poweroff"],
      ask: true
    }
  ]

  function run(action: var) {
    if (action.ask && armed !== action.id) {
      armed = action.id;
      settle.restart();
      return;
    }
    armed = "";
    Menus.close();
    Quickshell.execDetached(action.command);
  }

  readonly property var asked: actions.find(a => a.id === armed) ?? null

  spacing: 6
  Layout.fillWidth: true

  Timer {
    id: settle
    interval: 3000
    onTriggered: root.armed = ""
  }

  GridLayout {
    columns: 2
    rowSpacing: 6
    columnSpacing: 6
    Layout.fillWidth: true

    Repeater {
      model: root.actions

      Clickable {
        id: button

        required property var modelData
        required property int index
        readonly property bool isArmed: root.armed === modelData.id

        Layout.fillWidth: true
        Layout.preferredWidth: 1
        // an odd one out spans the row
        Layout.columnSpan: index === root.actions.length - 1 && root.actions.length % 2 === 1 ? 2 : 1
        implicitHeight: 34
        fill: true
        padX: 10
        spacing: 8
        radius: Theme.radiusControl + 2
        color: isArmed ? Theme.critical : Theme.sectionBg
        hoverColor: isArmed ? Qt.lighter(Theme.critical, 1.12) : Theme.accentActive
        pressColor: isArmed ? Qt.darker(Theme.critical, 1.1) : Qt.rgba(250 / 255, 189 / 255, 47 / 255, 0.3)
        onClicked: root.run(modelData)

        Glyph {
          text: button.modelData.icon
          color: button.isArmed ? Theme.accentInk : Theme.accent
          font.pixelSize: 16
          Layout.preferredWidth: 18
        }

        Txt {
          text: button.modelData.label
          color: button.isArmed ? Theme.accentInk : Theme.fgBright
          font.pixelSize: 12
          elide: Text.ElideRight
          Layout.fillWidth: true
        }
      }
    }
  }

  // what the second click will do
  Txt {
    visible: root.asked !== null
    text: root.asked ? `Click again to ${root.asked.label.toLowerCase()}` : ""
    color: Theme.critical
    font.pixelSize: 12
    horizontalAlignment: Text.AlignHCenter
    Layout.fillWidth: true
  }
}
