import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.services

// Tailscale (services/Tailscale.qml): its switch, or a sign-in while it is
// signed out, and folded under the chevron this device on the tailnet, the
// exit node, the settings tailscaled changes at run time, the tailnet's
// devices and the log-out
ColumnLayout {
  id: root

  readonly property string backend: Tailscale.backend
  readonly property bool signedOut: backend === "NeedsLogin"
  property bool open: false
  property bool choosingExit: false
  property bool showOffline: false
  readonly property var online: Tailscale.peers.filter(p => p.online)
  readonly property var offline: Tailscale.peers.filter(p => !p.online)

  // a switch for one of tailscaled's settings; a click while a change is
  // still going through is dropped, as it would act on the old value
  component Setting: RowLayout {
    id: setting

    property string label: ""
    property bool checked: false
    signal toggled

    spacing: 8
    Layout.fillWidth: true
    Layout.topMargin: 2

    Txt {
      text: setting.label
      color: Theme.fgBright
      font.pixelSize: 12
      elide: Text.ElideRight
      Layout.fillWidth: true
    }

    Toggle {
      checked: setting.checked
      onToggled: {
        if (!Tailscale.busy)
          setting.toggled();
      }
      Accessible.name: setting.label
    }
  }

  spacing: 8
  Layout.fillWidth: true

  RowLayout {
    spacing: 8

    Glyph {
      text: Icons.tailscale
      color: Tailscale.running ? Theme.accent : Theme.fg
      font.pixelSize: 18
      Layout.preferredWidth: 24
    }

    ColumnLayout {
      spacing: 0
      Layout.fillWidth: true

      Txt {
        text: "Tailscale"
        color: Theme.fgBright
        font.pixelSize: 13
        font.weight: Font.Medium
      }

      Txt {
        font.pixelSize: 12
        elide: Text.ElideRight
        Layout.fillWidth: true
        color: Tailscale.running && Tailscale.exitNode && !Tailscale.exitNode.online ? Theme.critical : Theme.fg
        text: {
          if (Tailscale.busy)
            return Tailscale.doing;
          switch (root.backend) {
          case "":
            return "tailscaled is not running";
          case "NeedsLogin":
            return Tailscale.authUrl !== "" ? "Finish signing in in the browser" : "Signed out";
          case "NeedsMachineAuth":
            return "Waiting for the admin to approve this device";
          case "Stopped":
            return "Off";
          case "Running":
            if (Tailscale.exitNode)
              return Tailscale.exitNode.online ? `Connected · via ${Tailscale.exitNode.name}` : `Exit node ${Tailscale.exitNode.name} offline`;
            return Tailscale.ipv4 !== "" ? `Connected · ${Tailscale.ipv4}` : "Connected";
          default:
            return "Connecting…";
          }
        }
      }
    }

    Clickable {
      id: fold

      visible: root.backend !== "" && !root.signedOut
      radius: Theme.radiusControl
      implicitWidth: 28
      implicitHeight: 28
      color: root.open ? Theme.accentActive : "transparent"
      onClicked: root.open = !root.open

      Chevron {
        open: root.open
        color: Theme.fgBright
        font.pixelSize: 16
      }

      Tooltip {
        target: fold
        hovered: fold.containsMouse && !root.open
        text: "Tailnet, exit node and devices"
      }
    }

    TextButton {
      visible: root.signedOut
      text: Tailscale.authUrl !== "" ? "Open" : "Log in"
      primary: true
      enabled: !Tailscale.busy
      onClicked: Tailscale.signIn()
    }

    Toggle {
      visible: root.backend !== "" && !root.signedOut
      checked: Tailscale.on
      onToggled: {
        if (!Tailscale.busy)
          Tailscale.toggle();
      }
      Accessible.name: "Tailscale"
    }
  }

  Txt {
    visible: Tailscale.error !== ""
    text: Tailscale.error
    color: Theme.critical
    font.pixelSize: 12
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
    Layout.leftMargin: 32
  }

  ColumnLayout {
    visible: root.open && root.backend !== "" && !root.signedOut
    spacing: 4
    Layout.fillWidth: true
    Layout.leftMargin: 32

    InfoRow {
      key: "Tailnet"
      value: Tailscale.tailnet
    }
    InfoRow {
      key: "Name"
      value: Tailscale.dnsName
    }
    InfoRow {
      key: "IPv4"
      value: Tailscale.ipv4
    }
    InfoRow {
      key: "IPv6"
      value: Tailscale.ipv6
    }
    InfoRow {
      key: "Account"
      value: Tailscale.account
    }

    Repeater {
      model: Tailscale.health

      Txt {
        required property string modelData

        text: modelData
        color: Theme.orange
        font.pixelSize: 12
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
      }
    }

    // the exit node: a row like the ones above that opens the choice
    Clickable {
      id: exitRow

      visible: Tailscale.running && (Tailscale.exitNodes.length > 0 || Tailscale.exitNode !== null)
      Layout.fillWidth: true
      Layout.leftMargin: -4
      Layout.topMargin: 4
      fill: true
      padX: 4
      padY: 3
      radius: Theme.radiusControl
      spacing: 8
      color: root.choosingExit ? Theme.accentActive : "transparent"
      onClicked: root.choosingExit = !root.choosingExit

      Txt {
        text: "Exit node"
        font.pixelSize: 12
        Layout.preferredWidth: 76
      }

      Txt {
        text: Tailscale.exitNode?.name ?? "None"
        color: Tailscale.exitNode ? (Tailscale.exitNode.online ? Theme.accent : Theme.critical) : Theme.fgBright
        font.pixelSize: 12
        elide: Text.ElideRight
        Layout.fillWidth: true
      }

      Chevron {
        open: root.choosingExit
        color: Theme.fgBright
        font.pixelSize: 14
      }
    }

    // the nodes offering to be one, on an inset like the audio device list;
    // offline ones show but cannot be picked
    Rectangle {
      visible: exitRow.visible && root.choosingExit
      Layout.fillWidth: true
      implicitHeight: exits.implicitHeight + 8
      radius: Theme.radiusControl
      color: Qt.rgba(29 / 255, 32 / 255, 33 / 255, 0.6)

      ColumnLayout {
        id: exits
        anchors.fill: parent
        anchors.margins: 4
        spacing: 0

        Repeater {
          model: [null].concat(Tailscale.exitNodes)

          Clickable {
            id: option

            required property var modelData
            readonly property bool isCurrent: (modelData?.id ?? null) === (Tailscale.exitNode?.id ?? null)

            Layout.fillWidth: true
            fill: true
            padX: 6
            padY: 6
            radius: Theme.radiusControl - 2
            spacing: 8
            enabled: modelData === null || modelData.online
            onClicked: {
              root.choosingExit = false;
              if (!isCurrent && !Tailscale.busy)
                Tailscale.useExitNode(modelData);
            }

            Txt {
              text: option.modelData?.name ?? "None"
              color: option.isCurrent ? Theme.accent : Theme.fgBright
              font.pixelSize: 12
              elide: Text.ElideRight
              Layout.fillWidth: true
            }

            Txt {
              visible: option.modelData !== null && !option.modelData.online
              text: "offline"
              font.pixelSize: 12
            }

            Glyph {
              text: option.isCurrent ? Icons.check : ""
              font.pixelSize: 14
              Layout.preferredWidth: 14
            }
          }
        }
      }
    }

    // tailscaled's settings that `tailscale set` changes in place
    Setting {
      visible: Tailscale.exitNode !== null
      label: "Local network access"
      checked: Tailscale.allowLan
      onToggled: Tailscale.setPref("exit-node-allow-lan-access", !checked)
    }
    Setting {
      label: "Subnet routes"
      checked: Tailscale.acceptRoutes
      onToggled: Tailscale.setPref("accept-routes", !checked)
    }
    Setting {
      label: "Tailnet DNS"
      checked: Tailscale.acceptDns
      onToggled: Tailscale.setPref("accept-dns", !checked)
    }
    // shields up refuses them; the switch says what is let in
    Setting {
      label: "Incoming connections"
      checked: !Tailscale.shieldsUp
      onToggled: Tailscale.setPref("shields-up", checked)
    }

    // the tailnet's devices
    ColumnLayout {
      visible: Tailscale.running && Tailscale.peers.length > 0
      spacing: 0
      Layout.fillWidth: true
      Layout.topMargin: 8

      RowLayout {
        Layout.bottomMargin: 2

        Txt {
          text: "Devices"
          color: Theme.fgBright
          font.pixelSize: 12
          font.weight: Font.Medium
          Layout.fillWidth: true
        }

        Txt {
          text: `${root.online.length} online`
          font.pixelSize: 12
        }
      }

      Repeater {
        model: root.online

        TailscalePeer {}
      }

      Clickable {
        visible: root.offline.length > 0
        Layout.fillWidth: true
        Layout.leftMargin: -4
        fill: true
        padX: 4
        padY: 3
        radius: Theme.radiusControl
        spacing: 8
        onClicked: root.showOffline = !root.showOffline

        Txt {
          text: `${root.offline.length} offline`
          font.pixelSize: 12
          Layout.fillWidth: true
        }

        Chevron {
          open: root.showOffline
          color: Theme.fgBright
          font.pixelSize: 14
        }
      }

      Repeater {
        model: root.showOffline ? root.offline : []

        TailscalePeer {}
      }
    }

    // signing back in may need the admin again: asked twice
    ConfirmButton {
      text: "Log out"
      question: "Log out of the tailnet?"
      onConfirmed: Tailscale.logOut()
      Layout.topMargin: 6
    }
  }
}
