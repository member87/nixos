import QtQuick
import QtQuick.Layouts
import qs.common

// a hairline between the bar's groups on the right: the bar's own border
// colour, short of its edges, with room either side for the hover pills
Rectangle {
  implicitWidth: 1
  implicitHeight: 12
  color: Theme.border
  Layout.alignment: Qt.AlignVCenter
  Layout.leftMargin: 4
  Layout.rightMargin: 4
}
