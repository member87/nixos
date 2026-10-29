import QtQuick
import QtQuick.Layouts
import qs.common
import qs.services

// "Cleared 12 notifications · Undo", for as long as the clear can still be
// taken back; a hairline along its foot runs the time down
Rectangle {
  id: root

  readonly property var cleared: Notifs.cleared

  visible: cleared !== null
  Layout.fillWidth: true
  implicitHeight: row.implicitHeight + 16
  radius: Theme.radiusSection
  color: Theme.sectionBg
  clip: true

  // a new clear starts the clock again
  onClearedChanged: {
    if (cleared)
      countdown.restart();
  }

  RowLayout {
    id: row
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: 12
    anchors.rightMargin: 8
    spacing: 8

    Txt {
      text: root.cleared?.label ?? ""
      color: Theme.fgBright
      font.pixelSize: 13
      elide: Text.ElideRight
      Layout.fillWidth: true
    }

    TextButton {
      text: "Undo"
      primary: true
      onClicked: Notifs.undoClear()
    }
  }

  Rectangle {
    id: time

    property real remaining: 1

    x: root.radius
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 1
    width: (root.width - root.radius * 2) * remaining
    height: 2
    radius: 1
    color: Theme.accent
    opacity: 0.45

    NumberAnimation on remaining {
      id: countdown
      running: false
      from: 1
      to: 0
      duration: Notifs.undoFor
    }
  }
}
