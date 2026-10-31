import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.common
import qs.components
import qs.services

// power-profiles-daemon's profiles as one segmented row; the current one is
// filled with the accent. Hidden on hosts without the daemon (odin).
Section {
  visible: Power.available

  RowLayout {
    spacing: 8
    Layout.fillWidth: true

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
        padY: 10
        // inside a section, so a step less round than it (like the tiles)
        radius: Theme.radiusControl + 2
        color: selected ? Theme.accent : "transparent"
        hoverColor: selected ? Qt.lighter(Theme.accent, 1.12) : Theme.accentHover
        pressColor: selected ? Qt.darker(Theme.accent, 1.1) : Theme.accentActive
        onClicked: Power.set(modelData.profile)

        // icon over label: three labelled icons side by side don't fit the
        // menu's width with room to breathe
        ColumnLayout {
          spacing: 4

          Glyph {
            text: segment.modelData.icon
            color: segment.selected ? Theme.accentInk : Theme.accent
            font.pixelSize: 20
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
