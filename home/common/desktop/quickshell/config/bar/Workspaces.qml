import QtQuick
import Quickshell.Hyprland
import qs.common
import qs.components

// Workspaces 1-10, always shown: the ones holding windows bright, the empty
// ones dim, one that wants attention in red. The focused one sits in an
// 18px accent pill that travels to the next: its leading edge gets there
// first and the trailing one follows, so it stretches on the way and
// gathers up on arrival.
Item {
  id: root

  readonly property int focusedId: Hyprland.focusedWorkspace?.id ?? -1
  readonly property int size: 18
  readonly property int gap: 2
  readonly property real slot: size + gap
  // which way the pill last moved: its edges swap speeds with it
  property bool forward: true
  // no travel on the first placement, at startup
  property bool placed: false

  function place() {
    if (focusedId < 1 || focusedId > 10)
      return;
    const x = (focusedId - 1) * slot;
    forward = x > pill.startX;
    pill.startX = x;
    pill.endX = x + size;
    placed = true;
  }

  onFocusedIdChanged: place()
  Component.onCompleted: place()

  implicitWidth: row.implicitWidth
  implicitHeight: Theme.barHeight

  Rectangle {
    id: pill

    property real startX: 0
    property real endX: root.size

    anchors.verticalCenter: parent.verticalCenter
    x: startX
    width: endX - startX
    height: root.size
    radius: root.size / 2
    color: Theme.accent
    // a special workspace (or none yet): the pill steps aside
    opacity: root.focusedId >= 1 && root.focusedId <= 10 ? 1 : 0

    Behavior on startX {
      enabled: root.placed
      NumberAnimation {
        duration: Theme.ms(root.forward ? 240 : 120)
        easing.type: Theme.easeOut
      }
    }

    Behavior on endX {
      enabled: root.placed
      NumberAnimation {
        duration: Theme.ms(root.forward ? 120 : 240)
        easing.type: Theme.easeOut
      }
    }

    Behavior on opacity {
      NumberAnimation {
        duration: Theme.fast
      }
    }
  }

  Row {
    id: row
    spacing: root.gap

    Repeater {
      model: 10

      MouseArea {
        id: entry

        required property int index
        readonly property int wsId: index + 1
        readonly property bool selected: root.focusedId === wsId
        readonly property var workspace: Hyprland.workspaces.values.find(w => w.id === entry.wsId) ?? null
        readonly property bool occupied: (workspace?.toplevels.values.length ?? 0) > 0
        readonly property bool urgent: workspace?.urgent ?? false

        // every entry reserves the pill's width so switching never shifts
        // the neighbouring numbers
        width: root.size
        height: Theme.barHeight
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Hyprland.dispatch(`workspace ${wsId}`)

        Txt {
          anchors.centerIn: parent
          text: entry.wsId
          color: {
            if (entry.selected)
              return Theme.accentInk;
            if (entry.urgent)
              return Theme.critical;
            if (entry.occupied || entry.containsMouse)
              return Theme.fgBright;
            return Theme.fg;
          }
          // empty ones recede; still legible
          opacity: entry.selected || entry.occupied || entry.urgent || entry.containsMouse ? 1 : 0.55
          font.weight: entry.occupied || entry.selected ? Font.Medium : Font.Normal

          Behavior on opacity {
            NumberAnimation {
              duration: Theme.fast
            }
          }
        }
      }
    }
  }

  WheelHandler {
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    onWheel: e => Hyprland.dispatch(e.angleDelta.y < 0 ? "workspace +1" : "workspace -1")
  }
}
