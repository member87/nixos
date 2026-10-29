import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.common
import qs.components
import qs.services

// The newest notifications, one line of each: a click runs it as in the
// notification centre, the rest of the history opens the centre itself.
ColumnLayout {
  id: root

  required property string screenName
  // the heading matches the date across Tux
  required property int headingSize
  required property int gap
  property int rows: 4

  readonly property var shown: Notifs.entries.slice(0, rows)
  readonly property int more: Notifs.count - shown.length

  spacing: 6

  RowLayout {
    Layout.fillWidth: true
    Layout.bottomMargin: Math.round(root.gap * 0.6) - root.spacing
    spacing: 12

    Txt {
      text: Notifs.count === 0 ? "No notifications" : Notifs.count === 1 ? "1 notification" : `${Notifs.count} notifications`
      color: Theme.fgBright
      font.pixelSize: root.headingSize
      font.weight: Font.Medium
      Layout.fillWidth: true
    }

    TextButton {
      visible: Notifs.count > 0
      text: "Clear all"
      onClicked: Notifs.clearAll()
    }
  }

  Repeater {
    model: root.shown

    Clickable {
      id: row

      required property var modelData
      readonly property string picture: modelData.image || Notifs.keepable(modelData.appIcon)
      readonly property string icon: picture === "" && modelData.appIcon !== "" ? Quickshell.iconPath(modelData.appIcon, true) : ""

      fill: true
      padX: 10
      padY: 8
      spacing: 12
      Layout.fillWidth: true
      Layout.leftMargin: -10
      Layout.rightMargin: -10
      onClicked: Notifs.activate(modelData)

      ClippingRectangle {
        implicitWidth: 32
        implicitHeight: 32
        Layout.alignment: Qt.AlignTop
        radius: 5
        color: "transparent"

        Image {
          anchors.fill: parent
          visible: row.picture !== ""
          source: row.picture
          sourceSize: Qt.size(64, 64)
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
        }

        IconImage {
          anchors.centerIn: parent
          visible: row.picture === "" && row.icon !== ""
          implicitSize: 28
          source: row.icon
        }

        Glyph {
          anchors.centerIn: parent
          visible: row.picture === "" && row.icon === ""
          text: Icons.notification
          font.pixelSize: 20
        }
      }

      ColumnLayout {
        spacing: 2
        Layout.fillWidth: true

        Txt {
          text: row.modelData.summary || row.modelData.appName || "Notification"
          color: Theme.fgBright
          font.pixelSize: 15
          font.weight: Font.Bold
          elide: Text.ElideRight
          Layout.fillWidth: true
        }

        // the body as one line of plain text; the app when there is none
        Txt {
          visible: text !== "" && text !== row.modelData.summary
          text: (row.modelData.body ?? "").replace(/<[^>]*>/g, "").replace(/\s+/g, " ").trim() || row.modelData.appName || ""
          font.pixelSize: 14
          elide: Text.ElideRight
          Layout.fillWidth: true
        }
      }

      Txt {
        Layout.alignment: Qt.AlignTop
        text: Notifs.age(row.modelData)
        font.pixelSize: 13
      }
    }
  }

  Clickable {
    visible: root.more > 0
    padX: 10
    padY: 6
    radius: 5
    Layout.leftMargin: -10
    onClicked: Menus.toggle(root.screenName, "notifications")

    Txt {
      text: `${root.more} more in the notification centre`
      color: Theme.accent
      font.pixelSize: 14
    }
  }
}
