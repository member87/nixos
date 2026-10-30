//@ pragma IconTheme oomox-gruvbox-dark

// The screen-share picker, in place of hyprland-share-picker: when an app
// asks to share the screen, xdg-desktop-portal-hyprland runs it (its
// screencopy:custom_picker_binary, the quickshell-share-picker wrapper in
// default.nix) and reads the choice back. A card over the dimmed screen
// shows a still of every screen and window it may share; a click shares
// one, or the region tile lets a drag cut out part of a screen.
//
// The choice goes to $QS_SHARE_OUT as xdph's selection ("r/screen:DP-1",
// "/window:<handle>", "/region:DP-1@x,y,w,h"); nothing written is a cancel.
// Run by hand (qs -p sharepicker.qml) it lists every window and logs the
// choice instead.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.common
import qs.components
import qs.share

ShellRoot {
  id: root

  readonly property string outPath: Quickshell.env("QS_SHARE_OUT") ?? ""
  // a restore token lets the app share the same thing again without asking
  property bool allowToken: Quickshell.env("QS_SHARE_ALLOW_TOKEN") === "1"
  // "pick" | "region"
  property string mode: "pick"

  // xdph's windows, each "handle[HC>]class[HT>]title[HE>]address[HA>]";
  // the address is Hyprland's, in decimal (0 when xdph could not map it)
  readonly property var offered: {
    const list = Quickshell.env("XDPH_WINDOW_SHARING_LIST");
    if (list === null || list === undefined)
      return null;
    return list.split("[HA>]").map(e => e.match(/^([\s\S]*?)\[HC>\]([\s\S]*?)\[HT>\]([\s\S]*?)\[HE>\]([\s\S]*)$/)).filter(m => m !== null).map(m => ({
          handle: m[1],
          cls: m[2],
          title: m[3],
          address: Number(m[4])
        }));
  }

  // the offered windows (every window, run by hand) with their Hyprland
  // toplevel for the still and the workspace, in workspace order
  readonly property var windows: {
    const tops = Hyprland.toplevels.values;
    const classOf = t => t.lastIpcObject?.class ?? "";
    const entries = offered ?? tops.map(t => ({
          handle: t.address,
          cls: classOf(t),
          title: t.title,
          address: parseInt(t.address, 16)
        }));
    const order = w => {
      const id = w.toplevel?.workspace?.id ?? 0;
      return id > 0 ? id : 1e6 - id;
    };
    return entries.map(e => ({
          handle: e.handle,
          cls: e.cls,
          title: e.title,
          toplevel: tops.find(t => e.address !== 0 && parseInt(t.address, 16) === e.address) ?? tops.find(t => t.title === e.title && classOf(t) === e.cls) ?? null
        })).sort((a, b) => order(a) - order(b));
  }

  function share(selection: string) {
    const line = `${allowToken ? "r" : ""}/${selection}`;
    if (outPath === "") {
      console.info(`selection: ${line}`);
      Qt.quit();
      return;
    }
    out.setText(line);
  }

  function cancel() {
    Qt.quit();
  }

  function where(toplevel: var): string {
    const ws = toplevel?.workspace;
    if (!ws)
      return "";
    return ws.id > 0 ? `workspace ${ws.name}` : (ws.name.replace(/^special:?/, "") || "special") + " scratchpad";
  }

  Component.onCompleted: Hyprland.refreshToplevels()

  FileView {
    id: out
    path: root.outPath
    blockWrites: true
    onSaved: Qt.quit()
    onSaveFailed: Qt.quit()
  }

  PanelWindow {
    id: picker

    // the card shows once every screen's still is taken, so the stills hold
    // the desktop and not the picker over it
    property bool shown: false
    readonly property int columns: 3
    readonly property int gap: 16
    // stills are shaped like this screen (windows tiled on it share it), from
    // 16:10 to an ultrawide's 21:9
    readonly property real aspect: Math.max(16 / 10, Math.min(21 / 9, width / Math.max(1, height)))

    function reveal() {
      if (shown)
        return;
      shown = true;
      appear.restart();
      nav.forceActiveFocus();
      firstTile()?.forceActiveFocus();
    }

    function checkCaptured() {
      for (let i = 0; i < screenTiles.count; i++)
        if (!screenTiles.itemAt(i)?.captured)
          return;
      reveal();
    }

    function firstTile(): var {
      return screenTiles.count > 0 ? screenTiles.itemAt(0) : null;
    }

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell-share-picker"
    WlrLayershell.layer: WlrLayer.Overlay
    // a region drag takes the keyboard (and draws its own dim) over this
    // window; it stays mapped so the stills are not taken again
    WlrLayershell.keyboardFocus: root.mode === "pick" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: shown && root.mode === "pick" ? Qt.rgba(0, 0, 0, 0.55) : "transparent"

    // back from a region drag: the keyboard returns to the region tile
    Connections {
      target: root
      function onModeChanged() {
        if (root.mode === "pick") {
          nav.forceActiveFocus();
          regionTile.forceActiveFocus();
        }
      }
    }

    // a screen that never delivers a frame must not hold the picker back
    Timer {
      running: !picker.shown
      interval: 500
      onTriggered: picker.reveal()
    }

    ParallelAnimation {
      id: appear
      ColorAnimation {
        target: picker
        property: "color"
        from: "transparent"
        to: Qt.rgba(0, 0, 0, 0.55)
        duration: Theme.enter
        easing.type: Theme.easeOut
      }
      NumberAnimation {
        target: card
        property: "opacity"
        from: 0
        to: 1
        duration: Theme.enter
        easing.type: Theme.easeOut
      }
      NumberAnimation {
        target: nudge
        property: "y"
        from: 14
        to: 0
        duration: Theme.ms(260)
        easing.type: Theme.easeOut
      }
    }

    // a click outside the card cancels, like Escape
    MouseArea {
      anchors.fill: parent
      enabled: picker.shown && root.mode === "pick"
      onClicked: root.cancel()
    }

    PopupShadow {
      anchors.fill: card
      visible: card.visible
      radius: card.radius
      opacity: card.opacity
      transform: Translate {
        x: nudge.x
        y: nudge.y
      }
    }

    Rectangle {
      id: card

      anchors.centerIn: parent
      width: Math.min(parent.width - 160, 1280)
      height: Math.min(body.implicitHeight + 56, parent.height - 120)
      radius: Theme.radiusPanel
      color: Theme.bgSolid
      opacity: 0
      visible: root.mode === "pick"

      transform: Translate {
        id: nudge
      }

      // swallow clicks so they do not reach the cancelling area behind
      MouseArea {
        anchors.fill: parent
      }

      KeyNav {
        id: nav
        anchors.fill: parent
        anchors.margins: 28
        flick: flick
        onCancelled: root.cancel()

        ColumnLayout {
          id: body
          anchors.fill: parent
          spacing: 0

          RowLayout {
            spacing: 14
            Layout.fillWidth: true

            Glyph {
              text: "\u{F1483}"
              font.pixelSize: 30
              Layout.alignment: Qt.AlignTop
            }

            ColumnLayout {
              spacing: 4
              Layout.fillWidth: true

              Txt {
                text: "Choose what to share"
                color: Theme.accent
                font.pixelSize: 16
                font.bold: true
              }

              Txt {
                text: "Click a screen, a window or a region to start sharing it."
                color: Theme.fgBright
                font.pixelSize: 14
              }
            }
          }

          Flickable {
            id: flick
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 26
            Layout.preferredHeight: sections.implicitHeight
            Layout.minimumHeight: Math.min(sections.implicitHeight, 160)
            contentHeight: sections.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            readonly property real tileWidth: Math.floor((width - picker.gap * (picker.columns - 1)) / picker.columns)

            ColumnLayout {
              id: sections
              width: flick.width
              spacing: 0

              Txt {
                text: "Screens"
                color: Theme.fgBright
                font.pixelSize: 13
                font.bold: true
              }

              Grid {
                columns: picker.columns
                columnSpacing: picker.gap
                rowSpacing: 20
                Layout.topMargin: 12

                Repeater {
                  id: screenTiles
                  model: Quickshell.screens

                  ShareTile {
                    required property var modelData

                    width: flick.tileWidth
                    aspect: picker.aspect
                    source: modelData
                    glyph: "\u{F0379}"
                    title: modelData.name
                    detail: `${modelData.width} × ${modelData.height}`
                    onCapturedChanged: picker.checkCaptured()
                    onChosen: root.share(`screen:${modelData.name}`)
                  }
                }

                ShareTile {
                  id: regionTile
                  width: flick.tileWidth
                  aspect: picker.aspect
                  dashed: true
                  title: "Region"
                  detail: "Drag out part of a screen"
                  onChosen: root.mode = "region"
                }
              }

              Txt {
                text: "Windows"
                color: Theme.fgBright
                font.pixelSize: 13
                font.bold: true
                Layout.topMargin: 30
              }

              Txt {
                visible: root.windows.length === 0
                text: "No windows are open."
                font.pixelSize: 13
                Layout.topMargin: 12
              }

              Grid {
                visible: root.windows.length > 0
                columns: picker.columns
                columnSpacing: picker.gap
                rowSpacing: 20
                Layout.topMargin: 12

                Repeater {
                  model: root.windows

                  ShareTile {
                    required property var modelData
                    readonly property var entry: DesktopEntries.applications.values.length > 0 ? DesktopEntries.heuristicLookup(modelData.cls) : null

                    width: flick.tileWidth
                    aspect: picker.aspect
                    source: modelData.toplevel?.wayland ?? null
                    icon: entry?.icon ? Quickshell.iconPath(entry.icon, true) : ""
                    title: modelData.title || entry?.name || modelData.cls
                    detail: [entry?.name || modelData.cls, root.where(modelData.toplevel)].filter(s => s !== "").join(" · ")
                    onChosen: root.share(`window:${modelData.handle}`)
                  }
                }
              }
            }
          }

          RowLayout {
            spacing: 10
            Layout.fillWidth: true
            Layout.topMargin: 24

            Toggle {
              checked: root.allowToken
              onToggled: root.allowToken = !root.allowToken
            }

            Txt {
              text: "Let the app share this again without asking"
              font.pixelSize: 13
              Layout.fillWidth: true
            }

            TextButton {
              text: "Cancel"
              onClicked: root.cancel()
            }
          }
        }
      }

      // where the list is, when it scrolls
      Rectangle {
        visible: flick.contentHeight > flick.height
        x: card.width - 12
        y: nav.y + flick.y + flick.visibleArea.yPosition * flick.height
        width: 4
        height: flick.visibleArea.heightRatio * flick.height
        radius: 2
        color: Theme.border
      }
    }
  }

  Variants {
    model: Quickshell.screens

    RegionSelect {
      visible: root.mode === "region"
      onChosen: (output, region) => root.share(`region:${output}@${region}`)
      onBack: root.mode = "pick"
    }
  }
}
