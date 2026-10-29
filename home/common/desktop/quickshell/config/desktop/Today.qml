import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.services

// The date, then this month from Monday: the days gone by dimmed, today in
// the accent circle as in the bar's calendar. Set flush right, against Tux.
ColumnLayout {
  id: root

  required property int dateSize
  required property int gap

  readonly property int year: Time.now.getFullYear()
  readonly property int month: Time.now.getMonth()
  readonly property int today: Time.now.getDate()
  // blank cells before the 1st, and the month's length
  readonly property int offset: (new Date(year, month, 1).getDay() + 6) % 7
  readonly property int days: new Date(year, month + 1, 0).getDate()

  spacing: Math.round(gap * 0.6)

  Txt {
    Layout.alignment: Qt.AlignRight
    text: Qt.formatDateTime(Time.now, "dddd d MMMM")
    color: Theme.fgBright
    font.pixelSize: root.dateSize
    font.weight: Font.Medium
  }

  GridLayout {
    Layout.alignment: Qt.AlignRight
    columns: 7
    rowSpacing: 2
    columnSpacing: 2

    Repeater {
      model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

      Txt {
        required property string modelData
        required property int index

        text: modelData
        color: index >= 5 ? Theme.fg : Theme.fgBright
        font.pixelSize: 13
        horizontalAlignment: Text.AlignHCenter
        Layout.preferredWidth: 40
        Layout.preferredHeight: 28
      }
    }

    Repeater {
      // ints, so the cells are rebuilt once a month, not every minute
      model: root.offset + root.days

      Item {
        id: cell

        required property int index
        readonly property int day: index - root.offset + 1
        readonly property bool isToday: day === root.today

        Layout.preferredWidth: 40
        Layout.preferredHeight: 34

        Rectangle {
          anchors.centerIn: parent
          width: 30
          height: 30
          radius: 15
          color: Theme.accent
          visible: cell.isToday
        }

        Txt {
          anchors.centerIn: parent
          visible: cell.day >= 1
          text: cell.day
          font.pixelSize: 15
          font.weight: cell.isToday ? Font.Bold : Font.Normal
          font.features: {
            "cv11": 1
          }
          color: cell.isToday ? Theme.accentInk : cell.day < root.today ? Theme.fg : Theme.fgBright
          opacity: cell.day < root.today ? 0.6 : 1
        }
      }
    }
  }
}
