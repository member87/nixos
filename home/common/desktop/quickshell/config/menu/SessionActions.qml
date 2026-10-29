import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common
import qs.components
import qs.services

// Lock, suspend, log out, restart, shut down: the menu's first row. The
// three that end the session ask first, in place: one click turns the
// button red and says what a second click will do; left alone, it settles.
Section {
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
      command: ["hyprctl", "dispatch", "exit"],
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
      icon: "\u{F0425}",
      command: ["systemctl", "poweroff"],
      ask: true
    }
  ]
  readonly property var asked: actions.find(a => a.id === armed) ?? null

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

  padding: 6
  spacing: 6

  Timer {
    id: settle
    interval: 3000
    onTriggered: root.armed = ""
  }

  RowLayout {
    spacing: 6
    Layout.fillWidth: true

    Repeater {
      model: root.actions

      Clickable {
        id: button

        required property var modelData
        readonly property bool isArmed: root.armed === modelData.id

        Layout.fillWidth: true
        implicitHeight: 38
        radius: Theme.radiusControl + 2
        color: isArmed ? Theme.critical : "transparent"
        hoverColor: isArmed ? Qt.lighter(Theme.critical, 1.12) : Theme.accentHover
        pressColor: isArmed ? Qt.darker(Theme.critical, 1.1) : Theme.accentActive
        onClicked: root.run(modelData)

        Glyph {
          text: button.modelData.icon
          color: button.isArmed ? Theme.accentInk : Theme.accent
          font.pixelSize: 18
        }

        Tooltip {
          target: button
          hovered: button.containsMouse && !button.isArmed
          text: button.modelData.label
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
    Layout.bottomMargin: 2
  }
}
