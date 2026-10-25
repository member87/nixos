import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.common
import qs.components
import qs.services

// The volume / microphone / brightness popup, replacing swayosd. Volume and
// mute are watched in PipeWire, so it shows whatever changed them; the
// brightness keys call `qs -c bar ipc call osd brightness` after changing it.
// Quiet while the system menu is open (its sliders show the same thing).
PanelWindow {
  id: root

  // "volume" | "microphone" | "brightness"
  property string kind: "volume"
  // the first values after startup (or a device appearing) are not changes
  property bool ready: false

  readonly property real level: kind === "brightness" ? Brightness.value : kind === "microphone" ? Audio.inputVolume : Audio.volume
  readonly property bool muted: kind === "microphone" ? Audio.inputMuted : kind === "volume" ? Audio.muted : false

  function show(what: string) {
    if (!ready || Menus.screen !== "")
      return;
    kind = what;
    visible = true;
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
  implicitWidth: 320 + 32
  implicitHeight: 56 + 32
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
    onTriggered: root.visible = false
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
  }

  Rectangle {
    id: pill
    anchors.fill: parent
    anchors.margins: 16
    radius: height / 2
    color: Theme.bgSolid

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: 20
      anchors.rightMargin: 24
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
            duration: 120
            easing.type: Easing.OutCubic
          }
        }
      }
    }
  }
}
