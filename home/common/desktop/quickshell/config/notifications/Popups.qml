import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import Quickshell.Wayland
import qs.common
import qs.components
import qs.services

// Notification popups, top right of the focused monitor, newest on top.
// Low urgency stays 5s, normal 10s, critical until dismissed (swaync's
// timeouts); an app's own timeout wins. Hovering a popup holds it, and a
// hairline along its foot runs down the time it has left.
//
// A new popup slides in from the right edge, one that goes slides back out,
// and the rest close up. The model keeps each popup's delegate for as long
// as it is on screen (a plain array would rebuild them all, and restart
// their clocks, whenever one came or went).
PanelWindow {
  id: root

  readonly property int shadow: 16
  readonly property int cardWidth: 420
  // from the data, not the view: a view in an unmapped window does not lay
  // out, so its count would never rise to map it
  readonly property int count: Math.min(Notifs.popups.length, 5)
  // shown, or the last one still sliding out
  readonly property bool showing: count > 0 || linger.running

  onCountChanged: {
    if (count === 0)
      linger.restart();
  }

  screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
  // the open notification centre lists them all already
  visible: showing && (Menus.page !== "notifications" || Menus.screen === "")
  anchors {
    top: true
    right: true
  }
  margins {
    top: 8 - shadow
    right: 8 - shadow
  }
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "quickshell-notifications"
  WlrLayershell.layer: WlrLayer.Overlay
  color: "transparent"
  implicitWidth: cardWidth + shadow * 2
  // as tall as five popups may need: the cards slide inside it rather than
  // the window resizing under them. Clicks pass through all but the cards.
  implicitHeight: Math.round(screen.height * 0.8)
  mask: Region {
    item: cards
  }

  // the window outlives its last popup by the length of its exit
  Timer {
    id: linger
    interval: Theme.exit + 40
  }

  ListView {
    id: cards

    x: root.shadow
    y: root.shadow
    width: root.cardWidth
    height: contentHeight
    spacing: 8
    interactive: false

    model: ScriptModel {
      values: Notifs.popups.slice(0, 5)
    }

    // the ones waiting behind the five on screen
    footer: Item {
      id: overflow

      readonly property int waiting: Notifs.popups.length - 5

      width: ListView.view.width
      height: waiting > 0 ? more.implicitHeight + 8 : 0

      Clickable {
        id: more

        visible: overflow.waiting > 0
        anchors.right: parent.right
        y: 8
        padX: 12
        padY: 6
        radius: Theme.radiusControl + 2
        color: Theme.bgSolid
        hoverColor: Qt.tint(Theme.bgSolid, Theme.accentHover)
        onClicked: Menus.toggle(root.screen.name, "notifications")

        Txt {
          text: `${overflow.waiting} more in the notification centre`
          color: Theme.accent
          font.pixelSize: 12
        }
      }
    }

    add: Transition {
      NumberAnimation {
        property: "x"
        from: 72
        duration: Theme.enter
        easing.type: Theme.easeOut
      }
      NumberAnimation {
        property: "opacity"
        from: 0
        to: 1
        duration: Theme.enter
        easing.type: Theme.easeOut
      }
    }

    remove: Transition {
      NumberAnimation {
        property: "x"
        to: 72
        duration: Theme.exit
        easing.type: Theme.easeIn
      }
      NumberAnimation {
        property: "opacity"
        to: 0
        duration: Theme.exit
        easing.type: Theme.easeIn
      }
    }

    // the rest close up, or make room; a popup caught mid-entrance by
    // another lands fully visible
    displaced: Transition {
      NumberAnimation {
        property: "y"
        duration: Theme.enter
        easing.type: Theme.easeOut
      }
      NumberAnimation {
        property: "opacity"
        to: 1
        duration: Theme.enter
      }
      NumberAnimation {
        property: "x"
        to: 0
        duration: Theme.enter
        easing.type: Theme.easeOut
      }
    }

    delegate: Item {
      id: popup

      required property var modelData
      // the entry carries the live notification's copy (and any update)
      readonly property var entry: Notifs.entries.find(e => e.live === modelData) ?? null
      // what the card shows: the last entry, kept while a dismissed one
      // slides out after the history has let it go
      property var shown: null
      readonly property int timeout: {
        if (modelData?.expireTimeout > 0)
          return modelData.expireTimeout;
        if (modelData?.urgency === NotificationUrgency.Critical)
          return 0;
        return modelData?.urgency === NotificationUrgency.Low ? 5000 : 10000;
      }
      // the share of its time still to run
      property real remaining: 1

      onEntryChanged: {
        if (entry)
          shown = entry;
      }
      Component.onCompleted: shown = entry

      visible: shown !== null
      width: ListView.view.width
      height: shown ? card.implicitHeight : 0

      PopupShadow {
        anchors.fill: card
        radius: card.radius
      }

      NotificationCard {
        id: card
        width: parent.width
        entry: popup.shown ?? {}
      }

      // the time left, along the card's foot inside its corners
      Rectangle {
        visible: popup.timeout > 0
        x: card.radius
        anchors.bottom: card.bottom
        anchors.bottomMargin: 1
        width: (card.width - card.radius * 2) * popup.remaining
        height: 2
        radius: 1
        color: Theme.accent
        opacity: card.hovered ? 0.2 : 0.45

        Behavior on opacity {
          NumberAnimation {
            duration: Theme.fast
          }
        }
      }

      NumberAnimation on remaining {
        running: popup.timeout > 0
        paused: running && card.hovered
        from: 1
        to: 0
        duration: popup.timeout
        onFinished: Notifs.hidePopup(popup.modelData)
      }
    }
  }
}
