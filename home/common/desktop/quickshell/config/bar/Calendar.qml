import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common
import qs.components
import qs.services

// month calendar under the clock; weeks start on Monday, today is circled
// in the accent like the focused workspace. Scroll or the arrows change month.
BarPopup {
  id: root

  property real closedAt: 0
  // first day of the month on show
  property date month: new Date()

  readonly property var cells: {
    const first = new Date(month.getFullYear(), month.getMonth(), 1);
    const offset = (first.getDay() + 6) % 7;
    return Array.from({
      length: 42
    }, (_, i) => new Date(first.getFullYear(), first.getMonth(), 1 - offset + i));
  }

  function shift(months: int) {
    show(new Date(month.getFullYear(), month.getMonth() + months, 1));
  }

  // the next month comes in from the right, the last from the left
  function show(first: date) {
    const step = first.getTime() - month.getTime();
    if (step === 0)
      return;
    month = first;
    monthIn.from = step > 0 ? 10 : -10;
    monthIn.restart();
    monthFade.restart();
  }

  function sameDay(a: date, b: date): bool {
    return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
  }

  grabFocus: true
  visible: false
  // 7 day columns of 32 + 2px gaps, inside the section and panel padding
  panelWidth: 7 * 32 + 6 * 2 + 20 + 20
  panelHeight: body.implicitHeight + 20

  onVisibleChanged: {
    if (visible) {
      month = new Date(Time.now.getFullYear(), Time.now.getMonth(), 1);
      keys.forceActiveFocus();
    } else {
      closedAt = Date.now();
    }
  }

  Item {
    id: keys
    anchors.fill: parent
    focus: true

    // Left and Right (or Page Up and Down) turn the month, Home comes back
    // to this one, Escape closes
    Keys.onPressed: e => {
      if (e.key === Qt.Key_Left || e.key === Qt.Key_PageUp)
        root.shift(-1);
      else if (e.key === Qt.Key_Right || e.key === Qt.Key_PageDown)
        root.shift(1);
      else if (e.key === Qt.Key_Home)
        root.show(new Date(Time.now.getFullYear(), Time.now.getMonth(), 1));
      else if (e.key === Qt.Key_Escape)
        root.close();
      else
        return;
      e.accepted = true;
    }

    // one month per wheel notch; touchpads send many small deltas, so add
    // them up to a notch (120) before turning the page
    WheelHandler {
      property real acc: 0

      acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
      onWheel: e => {
        acc += e.angleDelta.y;
        if (Math.abs(acc) >= 120) {
          root.shift(acc < 0 ? 1 : -1);
          acc = 0;
        }
      }
    }

    // sized by its content (not anchored), so the window can follow its
    // implicit height
    ColumnLayout {
      id: body
      x: 10
      y: 10
      width: parent.width - 20
      spacing: 10

      // today, large, as in the system menu
      Rectangle {
        Layout.fillWidth: true
        implicitHeight: today.implicitHeight + 24
        radius: Theme.radiusSection
        color: Theme.sectionBg

        ColumnLayout {
          id: today
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          anchors.leftMargin: 16
          spacing: 2

          Txt {
            text: Time.day
            color: Theme.accent
            font.pixelSize: 18
            font.bold: true
          }

          Txt {
            text: Time.fullDate
            color: Theme.fgBright
            font.weight: Font.Medium
          }
        }
      }

      Section {
        spacing: 6

        RowLayout {
          spacing: 4

          Clickable {
            implicitWidth: 28
            implicitHeight: 28
            radius: Theme.radiusControl
            onClicked: root.shift(-1)

            Glyph {
              text: Icons.chevronLeft
              font.pixelSize: 18
            }
          }

          // back to this month
          Clickable {
            Layout.fillWidth: true
            padY: 4
            radius: Theme.radiusControl
            onClicked: root.show(new Date(Time.now.getFullYear(), Time.now.getMonth(), 1))

            Txt {
              text: Qt.formatDate(root.month, "MMMM yyyy")
              color: Theme.fgBright
              font.pixelSize: 13
              font.weight: Font.Medium
            }
          }

          Clickable {
            implicitWidth: 28
            implicitHeight: 28
            radius: Theme.radiusControl
            onClicked: root.shift(1)

            Glyph {
              text: Icons.chevronRight
              font.pixelSize: 18
            }
          }
        }

        // the weekdays stay put while the days below change month
        GridLayout {
          columns: 7
          columnSpacing: 2

          Repeater {
            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

            Txt {
              required property string modelData
              required property int index

              text: modelData
              color: index >= 5 ? Theme.fg : Theme.fgBright
              font.pixelSize: 12
              horizontalAlignment: Text.AlignHCenter
              Layout.preferredWidth: 32
              Layout.preferredHeight: 22
            }
          }
        }

        GridLayout {
          id: grid
          columns: 7
          rowSpacing: 2
          columnSpacing: 2
          // the section's spacing, less the rows' own
          Layout.topMargin: -4
          transform: Translate {
            id: gridShift
          }

          NumberAnimation {
            id: monthIn
            target: gridShift
            property: "x"
            to: 0
            duration: Theme.base
            easing.type: Theme.easeOut
          }

          NumberAnimation {
            id: monthFade
            target: grid
            property: "opacity"
            from: 0
            to: 1
            duration: Theme.base
            easing.type: Theme.easeOut
          }

          Repeater {
            model: root.cells

            Item {
              id: cell

              required property date modelData
              readonly property bool inMonth: modelData.getMonth() === root.month.getMonth()
              readonly property bool isToday: root.sameDay(modelData, Time.now)

              Layout.preferredWidth: 32
              Layout.preferredHeight: 28

              Rectangle {
                anchors.centerIn: parent
                width: 26
                height: 26
                radius: 13
                color: Theme.accent
                visible: cell.isToday
              }

              Txt {
                anchors.centerIn: parent
                text: cell.modelData.getDate()
                font.pixelSize: 13
                color: cell.isToday ? Theme.accentInk : cell.inMonth ? Theme.fgBright : Theme.fg
                opacity: cell.inMonth || cell.isToday ? 1 : 0.45
              }
            }
          }
        }
      }
    }
  }
}
