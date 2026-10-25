import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.common
import qs.components

// a tray item's DBus menu drawn in the bar's own style; submenus open in
// place with a back row
PopupWindow {
  id: root

  required property Item target
  property var handle: null
  property var stack: []
  // when the grab last dismissed it; see Tray's click handler
  property real closedAt: 0

  anchor.item: target
  anchor.edges: Edges.Bottom
  anchor.gravity: Edges.Bottom
  anchor.margins.top: 6 - surface.shadow
  anchor.adjustment: PopupAdjustment.All
  grabFocus: true
  visible: false
  color: "transparent"
  implicitWidth: Math.max(180, column.implicitWidth + 12) + surface.shadow * 2
  implicitHeight: column.implicitHeight + 12 + surface.shadow * 2
  mask: Region {
    item: surface.panel
  }
  onVisibleChanged: {
    if (!visible) {
      stack = [];
      closedAt = Date.now();
    }
  }

  QsMenuOpener {
    id: opener
    menu: root.stack.length > 0 ? root.stack[root.stack.length - 1] : root.handle
  }

  PopupSurface {
    id: surface

    ColumnLayout {
      id: column
      anchors.fill: parent
      anchors.margins: 6
      spacing: 0

      Clickable {
        visible: root.stack.length > 0
        Layout.fillWidth: true
        fill: true
        padX: 8
        padY: 5
        radius: 5
        onClicked: root.stack = root.stack.slice(0, -1)

        Glyph {
          text: Icons.chevronLeft
          font.pixelSize: 13
        }

        Txt {
          text: "Back"
          color: Theme.fgBright
          font.pixelSize: 13
          Layout.fillWidth: true
        }
      }

      Repeater {
        model: opener.children

        Item {
          id: entry

          required property QsMenuEntry modelData

          Layout.fillWidth: true
          implicitWidth: modelData.isSeparator ? 0 : row.implicitWidth
          implicitHeight: modelData.isSeparator ? 8 : row.implicitHeight

          Clickable {
            id: row
            visible: !entry.modelData.isSeparator
            anchors.fill: parent
            fill: true
            padX: 8
            padY: 5
            radius: 5
            spacing: 8
            enabled: entry.modelData.enabled
            onClicked: {
              if (entry.modelData.hasChildren) {
                root.stack = [...root.stack, entry.modelData];
              } else {
                entry.modelData.triggered();
                root.visible = false;
              }
            }

            Glyph {
              visible: entry.modelData.buttonType !== QsMenuButtonType.None
              font.pixelSize: 14
              text: {
                const on = entry.modelData.checkState === Qt.Checked;
                if (entry.modelData.buttonType === QsMenuButtonType.RadioButton)
                  return on ? "\u{F043E}" : "\u{F043D}";
                return on ? "\u{F0132}" : "\u{F0131}";
              }
            }

            IconImage {
              visible: entry.modelData.icon !== ""
              implicitSize: 16
              source: entry.modelData.icon
            }

            Txt {
              // DBus menu labels mark mnemonics with "_" ("__" is a literal one)
              text: entry.modelData.text.replace(/__/g, "\u0000").replace(/_/g, "").replace(/\u0000/g, "_")
              color: Theme.fgBright
              font.pixelSize: 13
              Layout.fillWidth: true
            }

            Glyph {
              visible: entry.modelData.hasChildren
              text: Icons.chevronRight
              color: Theme.fg
              font.pixelSize: 13
            }
          }
        }
      }
    }
  }
}
