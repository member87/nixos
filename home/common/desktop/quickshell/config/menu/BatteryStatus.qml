import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.services

// [icon] 3 h 18 min left ........  52%
//        ━━━━━━━━━━━──────────
// The brightness row's geometry with a meter for the slider: the estimate
// labels the bar (the state while UPower has none), the figure is the charge.
RowLayout {
  visible: Battery.present
  spacing: 8
  Layout.fillWidth: true

  Glyph {
    text: Icons.battery(Battery.percent, Battery.charging)
    color: Battery.percent <= 10 ? Theme.critical : Theme.accent
    font.pixelSize: 18
    horizontalAlignment: Text.AlignHCenter
    Layout.preferredWidth: 28
  }

  ColumnLayout {
    spacing: 0
    Layout.fillWidth: true

    RowLayout {
      spacing: 6
      Layout.fillWidth: true

      Txt {
        text: Battery.status
        color: Theme.fgBright
        font.pixelSize: 12
        elide: Text.ElideRight
        Layout.fillWidth: true
      }

      Txt {
        text: `${Battery.percent}%`
        font.pixelSize: 12
      }
    }

    // the slider's 18px, so the bar sits where the brightness trough does
    Item {
      Layout.fillWidth: true
      implicitHeight: 18

      Meter {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        fraction: Battery.percent / 100
      }
    }
  }
}
