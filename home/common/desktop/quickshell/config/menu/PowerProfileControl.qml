import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.common
import qs.components
import qs.services

// power-profiles-daemon's profiles as one segmented control on a tone-step
// tray; the current one is filled with the accent. Hidden on hosts without
// the daemon (odin).
Rectangle {
  visible: Power.available
  Layout.fillWidth: true
  implicitHeight: segments.implicitHeight + 6
  radius: Theme.radiusControl + 2
  color: Theme.sectionBg

  RowLayout {
    id: segments
    anchors.fill: parent
    anchors.margins: 3
    spacing: 4

    Repeater {
      model: [
        {
          profile: PowerProfile.PowerSaver,
          icon: Icons.powerSaver,
          label: "Saver"
        },
        {
          profile: PowerProfile.Balanced,
          icon: Icons.powerBalanced,
          label: "Balanced"
        },
        {
          profile: PowerProfile.Performance,
          icon: Icons.powerPerformance,
          label: "Performance"
        }
      ]

      Clickable {
        id: segment

        required property var modelData
        readonly property bool selected: Power.profile === modelData.profile

        Layout.fillWidth: true
        Layout.preferredWidth: 1
        enabled: modelData.profile !== PowerProfile.Performance || Power.hasPerformance
        padX: 8
        padY: 6
        // inside the tray, so a step less round than it
        radius: Theme.radiusControl
        color: selected ? Theme.accent : "transparent"
        hoverColor: selected ? Qt.lighter(Theme.accent, 1.12) : Theme.accentHover
        pressColor: selected ? Qt.darker(Theme.accent, 1.1) : Theme.accentActive
        onClicked: Power.set(modelData.profile)

        // icon over label: three labelled icons side by side don't fit the
        // menu's width with room to breathe
        ColumnLayout {
          spacing: 2

          Glyph {
            text: segment.modelData.icon
            color: segment.selected ? Theme.accentInk : Theme.accent
            font.pixelSize: 16
            Layout.alignment: Qt.AlignHCenter
          }

          Txt {
            text: segment.modelData.label
            color: segment.selected ? Theme.accentInk : Theme.fgBright
            font.pixelSize: 12
            Layout.alignment: Qt.AlignHCenter
          }
        }
      }
    }
  }
}
