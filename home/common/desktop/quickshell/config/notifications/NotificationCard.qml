import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import qs.common
import qs.components
import qs.services

// One history entry: its picture, app and age, summary, body and actions.
// A click on the card runs the default action, when the app offers one (and
// only then shows as clickable); the cross dismisses it.
// Entries restored from a previous session have no live notification and
// so no actions.
Rectangle {
  id: root

  required property var entry
  // popups pause their timeout while the pointer is on them
  readonly property bool hovered: hover.hovered
  readonly property bool critical: entry.urgency === NotificationUrgency.Critical
  readonly property string picture: entry.image || Notifs.keepable(entry.appIcon)
  readonly property string icon: picture === "" && entry.appIcon !== "" ? Quickshell.iconPath(entry.appIcon, true) : ""
  readonly property string code: Notifs.code(entry)
  readonly property var actions: entry.live ? entry.live.actions.filter(a => a.identifier !== "default" && a.text !== "") : []

  implicitHeight: content.implicitHeight + 24
  radius: Theme.radiusSection
  color: Theme.bgSolid
  border.width: critical ? 1 : 0
  border.color: Theme.critical

  HoverHandler {
    id: hover
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Notifs.hasDefault(root.entry) ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: Notifs.activate(root.entry)
    // in the centre the keyboard stops on the card: Enter opens it, Delete
    // dismisses it (so its cross needs no stop of its own)
    activeFocusOnTab: true
    Keys.onPressed: e => {
      if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space)
        Notifs.activate(root.entry);
      else if (e.key === Qt.Key_Delete || e.key === Qt.Key_Backspace)
        Notifs.dismiss(root.entry);
      else
        return;
      e.accepted = true;
    }
  }

  Rectangle {
    anchors.fill: parent
    radius: root.radius
    color: "transparent"
    border.width: 2
    border.color: Theme.accent
    visible: area.activeFocus && Menus.keyboard
  }

  RowLayout {
    id: content
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: 12
    spacing: 12

    ClippingRectangle {
      visible: root.picture !== "" || root.icon !== ""
      Layout.alignment: Qt.AlignTop
      implicitWidth: 44
      implicitHeight: 44
      radius: 6
      color: "transparent"

      Image {
        anchors.fill: parent
        visible: root.picture !== ""
        source: root.picture
        sourceSize: Qt.size(88, 88)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
      }

      IconImage {
        anchors.centerIn: parent
        visible: root.picture === ""
        implicitSize: 36
        source: root.icon
      }
    }

    ColumnLayout {
      spacing: 4
      Layout.fillWidth: true

      RowLayout {
        spacing: 8

        Txt {
          text: root.entry.appName || "Notification"
          font.pixelSize: 12
          elide: Text.ElideRight
          Layout.fillWidth: true
        }

        Txt {
          text: Notifs.age(root.entry)
          font.pixelSize: 12
        }

        Clickable {
          id: close

          implicitWidth: 22
          implicitHeight: 22
          radius: Theme.radiusControl
          activeFocusOnTab: false
          onClicked: Notifs.dismiss(root.entry)

          Glyph {
            text: Icons.close
            color: Theme.fg
            font.pixelSize: 14
          }
        }
      }

      Txt {
        visible: text !== ""
        text: root.entry.summary
        color: root.critical ? Theme.critical : Theme.fgBright
        font.pixelSize: 14
        font.weight: Font.Bold
        wrapMode: Text.Wrap
        maximumLineCount: 2
        elide: Text.ElideRight
        Layout.fillWidth: true
      }

      Txt {
        visible: text !== ""
        text: root.entry.body
        textFormat: Text.StyledText
        color: Theme.fg
        font.pixelSize: 13
        wrapMode: Text.Wrap
        maximumLineCount: 4
        elide: Text.ElideRight
        Layout.fillWidth: true
        onLinkActivated: link => Qt.openUrlExternally(link)
      }

      Flow {
        visible: root.actions.length > 0 || root.code !== ""
        spacing: 8
        Layout.fillWidth: true
        Layout.topMargin: 4

        TextButton {
          visible: root.code !== ""
          text: `Copy ${root.code}`
          primary: true
          onClicked: {
            Notifs.copy(root.code);
            Notifs.dismiss(root.entry);
          }
        }

        Repeater {
          model: root.actions

          TextButton {
            required property var modelData

            text: modelData.text
            onClicked: {
              modelData.invoke();
              Notifs.dismiss(root.entry);
            }
          }
        }
      }
    }
  }
}
