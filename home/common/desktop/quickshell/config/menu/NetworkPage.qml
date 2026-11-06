import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import qs.common
import qs.components
import qs.services

// Ethernet ports, the Wi-Fi card and the network it is on, the VPN, and the
// networks in range: one group each, hairlines between them.
ColumnLayout {
  id: root

  readonly property string internet: {
    if (!Networking.canCheckConnectivity)
      return "";
    switch (Networking.connectivity) {
    case NetworkConnectivity.Full:
      return "Reachable";
    case NetworkConnectivity.Limited:
      return "Limited";
    case NetworkConnectivity.Portal:
      return "Sign-in page required";
    case NetworkConnectivity.None:
      return "Unreachable";
    default:
      return "";
    }
  }
  // the connected network is listed in the Wi-Fi group, not here
  readonly property var others: Net.wifiNetworks.filter(n => !n.connected && n.name !== "").sort((a, b) => b.known - a.known || b.signalStrength - a.signalStrength)

  spacing: 10

  // scanning keeps the network list live; only while this tab is open
  Component.onCompleted: {
    if (Net.wifi)
      Net.wifi.scannerEnabled = true;
  }
  Component.onDestruction: {
    if (Net.wifi)
      Net.wifi.scannerEnabled = false;
  }

  PageHeader {
    title: "Network"
  }

  Txt {
    visible: Net.devices.length === 0
    text: "NetworkManager reports no network devices"
    font.pixelSize: 12
    Layout.leftMargin: 2
  }

  // ethernet ports
  Repeater {
    model: Net.wired

    ColumnLayout {
      id: wired

      required property var modelData
      readonly property bool up: modelData.state === ConnectionState.Connected

      spacing: 8
      Layout.fillWidth: true

      RowLayout {
        spacing: 8

        Glyph {
          text: Icons.ethernet
          color: wired.up ? Theme.accent : Theme.fg
          font.pixelSize: 18
          Layout.preferredWidth: 24
        }

        ColumnLayout {
          spacing: 0
          Layout.fillWidth: true

          Txt {
            text: "Ethernet"
            color: Theme.fgBright
            font.pixelSize: 13
            font.weight: Font.Medium
          }

          Txt {
            font.pixelSize: 12
            text: {
              const d = wired.modelData;
              if (d.state === ConnectionState.Connected)
                return d.linkSpeed > 0 ? `Connected · ${d.linkSpeed} Mb/s` : "Connected";
              if (d.state === ConnectionState.Connecting)
                return "Connecting…";
              if (d.state === ConnectionState.Disconnecting)
                return "Disconnecting…";
              return d.hasLink ? "Disconnected" : "Cable unplugged";
            }
          }
        }

        TextButton {
          visible: !wired.up && wired.modelData.hasLink && wired.modelData.network !== null
          text: "Connect"
          onClicked: wired.modelData.network.connect()
        }
      }

      ColumnLayout {
        visible: wired.up
        spacing: 4
        Layout.leftMargin: 32

        ConnInfo {
          id: wiredInfo
          iface: wired.up ? wired.modelData.name : ""
        }

        InfoRow {
          key: "Profile"
          value: wiredInfo.connection
        }
        InfoRow {
          key: "Internet"
          value: root.internet
        }
        InfoRow {
          key: "IPv4"
          value: wiredInfo.ipv4
        }
        InfoRow {
          key: "Gateway"
          value: wiredInfo.gateway
        }
        InfoRow {
          key: "DNS"
          value: wiredInfo.dns
        }
        InfoRow {
          key: "IPv6"
          value: wiredInfo.ipv6
        }
        InfoRow {
          key: "Interface"
          value: wired.modelData.name
        }
        InfoRow {
          key: "MAC"
          value: wired.modelData.address
        }

        TextButton {
          text: "Disconnect"
          onClicked: wired.modelData.disconnect()
          Layout.topMargin: 4
        }
      }

      Rule {
        Layout.topMargin: 2
      }
    }
  }

  // the wifi card, its switch and the network it is on
  ColumnLayout {
    id: wifi

    readonly property var network: Net.wifiNetwork

    visible: Net.wifi !== null
    spacing: 8
    Layout.fillWidth: true

    RowLayout {
      spacing: 8

      Glyph {
        text: Net.wifiEnabled ? (wifi.network ? Icons.wifi(Net.strength, Net.secured(wifi.network)) : Icons.wifiFull) : Icons.wifiOff
        color: wifi.network ? Theme.accent : Theme.fg
        font.pixelSize: 18
        Layout.preferredWidth: 24
      }

      ColumnLayout {
        spacing: 0
        Layout.fillWidth: true

        Txt {
          text: wifi.network ? wifi.network.name : "Wi-Fi"
          color: Theme.fgBright
          font.pixelSize: 13
          font.weight: Font.Medium
          elide: Text.ElideRight
          Layout.fillWidth: true
        }

        Txt {
          font.pixelSize: 12
          elide: Text.ElideRight
          Layout.fillWidth: true
          text: {
            if (!Networking.wifiHardwareEnabled)
              return "Wi-Fi blocked by hardware switch";
            if (!Net.wifiEnabled)
              return "Wi-Fi off";
            if (!wifi.network)
              return "Not connected";
            return `Connected · ${Net.strength}% · ${Net.securityName(wifi.network)}`;
          }
        }
      }

      Toggle {
        checked: Net.wifiEnabled
        enabled: Networking.wifiHardwareEnabled
        onToggled: Net.toggleWifi()
        Accessible.name: "Wi-Fi"
      }
    }

    ColumnLayout {
      visible: wifi.network !== null
      spacing: 4
      Layout.leftMargin: 32

      ConnInfo {
        id: wifiInfo
        iface: wifi.network ? Net.wifi.name : ""
      }

      InfoRow {
        key: "Internet"
        value: root.internet
      }
      InfoRow {
        key: "IPv4"
        value: wifiInfo.ipv4
      }
      InfoRow {
        key: "Gateway"
        value: wifiInfo.gateway
      }
      InfoRow {
        key: "DNS"
        value: wifiInfo.dns
      }
      InfoRow {
        key: "IPv6"
        value: wifiInfo.ipv6
      }
      InfoRow {
        key: "Interface"
        value: Net.wifi?.name ?? ""
      }
      InfoRow {
        key: "MAC"
        value: Net.wifi?.address ?? ""
      }

      RowLayout {
        spacing: 8
        Layout.topMargin: 4

        TextButton {
          text: "Disconnect"
          onClicked: wifi.network.disconnect()
        }

        // the saved password goes with it: asked twice
        ConfirmButton {
          text: "Forget"
          question: "Forget network?"
          onConfirmed: wifi.network.forget()
        }
      }
    }

    Rule {
      Layout.topMargin: 2
    }
  }

  // ProtonVPN: status only, it is brought up from its own app
  RowLayout {
    spacing: 8

    Glyph {
      text: Vpn.connected ? Icons.vpnLocked : Icons.vpnUnlocked
      color: Vpn.connected ? Theme.accent : Theme.fg
      font.pixelSize: 18
      Layout.preferredWidth: 24
    }

    ColumnLayout {
      spacing: 0
      Layout.fillWidth: true

      Txt {
        text: "VPN"
        color: Theme.fgBright
        font.pixelSize: 12
      }

      Txt {
        text: Vpn.connected ? `Connected · ${Vpn.ip}` : "Off"
        font.pixelSize: 12
      }
    }
  }

  // networks in range
  ColumnLayout {
    visible: Net.wifi !== null && Net.wifiEnabled
    spacing: 2
    Layout.fillWidth: true

    Rule {
      Layout.bottomMargin: 8
    }

    Txt {
      text: "Networks"
      color: Theme.fgBright
      font.pixelSize: 12
      font.weight: Font.Medium
      Layout.leftMargin: 2
      Layout.bottomMargin: 4
    }

    Txt {
      visible: root.others.length === 0
      text: "Searching for networks…"
      font.pixelSize: 12
      Layout.leftMargin: 2
    }

    Repeater {
      model: root.others

      WifiRow {}
    }
  }
}
