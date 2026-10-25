import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.common
import qs.components

Section {
  id: root

  readonly property var battery: UPower.displayDevice
  readonly property int percent: Math.round((battery?.percentage ?? 0) * 100)
  readonly property int state: battery?.state ?? UPowerDeviceState.Unknown

  visible: battery?.isLaptopBattery ?? false

  RowLayout {
    spacing: 8

    Glyph {
      text: Icons.battery(root.percent, root.state === UPowerDeviceState.Charging)
      font.pixelSize: 18
      Layout.preferredWidth: 26
    }

    Meter {
      Layout.fillWidth: true
      Layout.leftMargin: 4
      fraction: root.percent / 100
    }

    // one line: "85% (Charging)"
    Txt {
      text: {
        if (root.state === UPowerDeviceState.Charging)
          return `${root.percent}% (Charging)`;
        if (root.state === UPowerDeviceState.FullyCharged)
          return `${root.percent}% (Full)`;
        return `${root.percent}%`;
      }
      color: Theme.fgBright
      font.pixelSize: 13
    }
  }
}
