import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.common
import qs.components
import qs.services

// The desktop of an empty workspace, laid out on the wallpaper's stripes:
// the clock and the record stand on them either side of Tux, the date with
// the month and the notifications hang under them. Each widget
// slides out from behind the stripes when an empty workspace comes up and
// back behind them when a window opens. One per screen, under the windows.
PanelWindow {
  id: root

  required property var modelData

  readonly property var workspace: Hyprland.monitorFor(modelData)?.activeWorkspace ?? null
  readonly property bool empty: workspace !== null && workspace.toplevels.values.length === 0
  // the widgets are out, or on their way
  property bool shown: false

  signal entered
  signal left

  // the wallpaper (hyprpaper.nix, 3840x2160) as hyprpaper draws it: scaled
  // to cover the screen and centred. Its stripes run from y 985 to 1175,
  // 38px a band; Tux sits between x 1728 and 2110.
  readonly property real cover: Math.max(width / 3840, height / 2160)
  readonly property real stripeTop: Math.round(985 * cover - (2160 * cover - height) / 2)
  readonly property real stripeBottom: Math.round(1175 * cover - (2160 * cover - height) / 2)
  readonly property real tuxLeft: 1728 * cover - (3840 * cover - width) / 2
  readonly property real tuxRight: 2110 * cover - (3840 * cover - width) / 2

  // one gap everywhere: a stripe's width
  readonly property int gap: Math.round(38 * cover)
  // the wings' inner edges, clear of Tux
  readonly property real leftEdge: Math.round(tuxLeft - gap * 2.5)
  readonly property real rightEdge: Math.round(tuxRight + gap * 2.5)
  readonly property real wing: leftEdge - gap * 2

  readonly property int clockSize: Math.round(height * 0.135)
  readonly property int figureSize: Math.round(Math.max(24, height * 0.022))

  function sync() {
    if (empty) {
      hide.stop();
      visible = true;
      shown = true;
      entered();
    } else if (shown) {
      shown = false;
      left();
      hide.restart();
    }
  }

  // a workspace swap fires both; one replay
  onEmptyChanged: Qt.callLater(sync)
  onWorkspaceChanged: Qt.callLater(sync)
  Component.onCompleted: Qt.callLater(sync)

  screen: modelData
  visible: false
  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "quickshell-desktop"
  WlrLayershell.layer: WlrLayer.Bottom
  color: "transparent"

  // unmapped once everything has sunk back
  Timer {
    id: hide
    interval: 260
    onTriggered: root.visible = false
  }

  // above the stripes: widgets rise out of their top edge
  Item {
    width: parent.width
    height: root.stripeTop
    clip: true

    Rise {
      stage: root
      order: 0
      x: root.leftEdge - width
      y: root.stripeTop - root.gap - clock.baselineOffset

      Txt {
        id: clock
        text: Time.time
        color: Theme.fgBright
        font.pixelSize: root.clockSize
        font.weight: Font.Bold
        font.letterSpacing: -root.clockSize * 0.03
        // FiraCode's slashed zero is for code; a clock wants the plain one
        font.features: {
          "cv11": 1
        }
        renderType: Text.QtRendering
      }
    }

    Rise {
      stage: root
      order: 1
      x: root.rightEdge
      y: root.stripeTop - root.gap - height

      NowPlaying {
        // the cover as tall as the clock's digits
        size: Math.round(root.clockSize * 0.74)
        titleSize: root.figureSize
        lyricSize: Math.round(Math.max(18, root.height * 0.0167))
        maxWidth: root.wing
        live: root.shown
      }
    }
  }

  // under the stripes: widgets drop out of their bottom edge
  Item {
    y: root.stripeBottom
    width: parent.width
    height: root.height - root.stripeBottom
    clip: true

    Rise {
      stage: root
      order: 2
      above: false
      x: root.leftEdge - width
      y: root.gap

      Today {
        dateSize: root.figureSize
        gap: root.gap
      }
    }

    Rise {
      stage: root
      order: 3
      above: false
      x: root.rightEdge
      y: root.gap

      Recent {
        width: Math.min(560, root.wing)
        headingSize: root.figureSize
        gap: root.gap
        screenName: root.modelData.name
        // what fits above the screen's bottom edge, at most five
        rows: Math.max(1, Math.min(5, Math.floor((root.height - root.stripeBottom - root.gap * 6) / 64)))
      }
    }
  }
}
