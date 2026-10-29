import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.common
import qs.components
import qs.services

// The volume / microphone / brightness popup, replacing swayosd, and the song
// a skip lands on. Volume and mute are watched in PipeWire, so it shows
// whatever changed them; the brightness keys call
// `qs -c bar ipc call osd brightness` after changing it; skips come from
// Media wherever they were made, and a song ending into the next is not one.
// Quiet while the system menu is open (it shows the same things). It rises
// a little as it fades in and sinks as it fades out; while it is up, a new
// change only updates it.
PanelWindow {
  id: root

  // "volume" | "microphone" | "brightness" | "track"
  property string kind: "volume"
  // the first values after startup (or a device appearing) are not changes
  property bool ready: false

  readonly property real level: kind === "brightness" ? Brightness.value : kind === "microphone" ? Audio.inputVolume : Audio.volume
  readonly property bool muted: kind === "microphone" ? Audio.inputMuted : kind === "volume" ? Audio.muted : false

  readonly property var player: Media.player

  function show(what: string) {
    if (!ready || Menus.screen !== "")
      return;
    kind = what;
    if (!visible || leave.running) {
      leave.stop();
      visible = true;
      arrive.restart();
    }
    // a song's name takes longer to read than a level
    hide.interval = what === "track" ? 2500 : 1400;
    hide.restart();
  }

  screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
  visible: false
  anchors.bottom: true
  margins.bottom: 80 - 16
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "quickshell-osd"
  WlrLayershell.layer: WlrLayer.Overlay
  color: "transparent"
  implicitWidth: (kind === "track" ? 420 : 320) + 32
  implicitHeight: (kind === "track" ? 72 : 56) + 32
  // never in the way of the pointer
  mask: Region {}

  Timer {
    interval: 1500
    running: true
    onTriggered: root.ready = true
  }

  Timer {
    id: hide
    interval: 1400
    onTriggered: leave.restart()
  }

  ParallelAnimation {
    id: arrive
    NumberAnimation {
      target: pill
      property: "opacity"
      to: 1
      duration: Theme.enter
      easing.type: Theme.easeOut
    }
    NumberAnimation {
      target: rise
      property: "y"
      to: 0
      duration: Theme.enter
      easing.type: Theme.easeOut
    }
  }

  SequentialAnimation {
    id: leave
    ParallelAnimation {
      NumberAnimation {
        target: pill
        property: "opacity"
        to: 0
        duration: Theme.exit
        easing.type: Theme.easeIn
      }
      NumberAnimation {
        target: rise
        property: "y"
        to: 10
        duration: Theme.exit
        easing.type: Theme.easeIn
      }
    }
    ScriptAction {
      script: root.visible = false
    }
  }

  Connections {
    target: Media
    function onSkipped() {
      root.show("track");
    }
  }

  Connections {
    target: Audio
    function onVolumeChanged() {
      root.show("volume");
    }
    function onMutedChanged() {
      root.show("volume");
    }
    function onInputMutedChanged() {
      root.show("microphone");
    }
  }

  // a new default device brings its own volume: not a change to show
  Connections {
    target: Audio
    function onSinkChanged() {
      root.ready = false;
      settle.restart();
    }
  }

  Timer {
    id: settle
    interval: 500
    onTriggered: root.ready = true
  }

  IpcHandler {
    target: "osd"

    // no backlight (odin): nothing to show
    function brightness(): void {
      if (!Brightness.available)
        return;
      Brightness.refresh();
      root.show("brightness");
    }
  }

  PopupShadow {
    anchors.fill: pill
    radius: pill.radius
    opacity: pill.opacity
    transform: Translate {
      y: rise.y
    }
  }

  Rectangle {
    id: pill
    anchors.fill: parent
    anchors.margins: 16
    radius: height / 2
    color: Theme.bgSolid
    // starts below and clear; arrive brings it up
    opacity: 0
    transform: Translate {
      id: rise
      y: 10
    }

    RowLayout {
      visible: root.kind !== "track"
      anchors.fill: parent
      anchors.leftMargin: 20
      anchors.rightMargin: 22
      spacing: 16

      Glyph {
        text: root.kind === "brightness" ? Icons.brightness : root.kind === "microphone" ? Icons.microphone(root.muted) : Icons.volume(Math.round(root.level * 100), root.muted)
        color: root.muted ? Theme.fg : Theme.accent
        font.pixelSize: 22
        Layout.preferredWidth: 26
      }

      Meter {
        Layout.fillWidth: true
        fraction: root.muted ? 0 : root.level
        // smooth the steps of a held key
        Behavior on fraction {
          NumberAnimation {
            duration: Theme.fast
            easing.type: Theme.easeOut
          }
        }
      }

      // the level as a figure, for the step that a bar cannot show
      Txt {
        text: root.muted ? "off" : Math.round(root.level * 100)
        color: root.muted ? Theme.fg : Theme.fgBright
        font.pixelSize: 14
        font.weight: Font.Medium
        horizontalAlignment: Text.AlignRight
        Layout.preferredWidth: metrics.advanceWidth

        TextMetrics {
          id: metrics
          font.family: Theme.font
          font.pixelSize: 14
          font.weight: Font.Medium
          text: "100"
        }
      }
    }

    // the song a skip landed on: round cover as in the bar, title, artist
    RowLayout {
      visible: root.kind === "track"
      anchors.fill: parent
      anchors.leftMargin: 12
      anchors.rightMargin: 28
      spacing: 14

      ClippingRectangle {
        implicitWidth: 48
        implicitHeight: 48
        radius: 24
        color: Theme.sectionBg

        Image {
          anchors.fill: parent
          source: root.player?.trackArtUrl ?? ""
          sourceSize: Qt.size(96, 96)
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
        }
      }

      ColumnLayout {
        spacing: 2
        Layout.fillWidth: true

        Txt {
          text: root.player?.trackTitle || "Unknown track"
          color: Theme.fgBright
          font.pixelSize: 15
          font.weight: Font.Bold
          elide: Text.ElideRight
          Layout.fillWidth: true
        }

        Txt {
          text: root.player?.trackArtist || "Unknown artist"
          font.pixelSize: 13
          elide: Text.ElideRight
          Layout.fillWidth: true
        }
      }
    }
  }
}
