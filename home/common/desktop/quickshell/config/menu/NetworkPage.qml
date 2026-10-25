import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import qs.common
import qs.components
import qs.services

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
  // the connected network is listed in the Wi-Fi section, not here
  readonly property var others: Net.wifiNetworks.filter(n => !n.connected && n.name !== "").sort((a, b) => b.known - a.known || b.signalStrength - a.signalStrength)

  spacing: 10

  // scanning keeps the network list live; only while this page is open
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

  Section {
    visible: Net.devices.length === 0

    Txt {
      text: "NetworkManager reports no network devices"
      font.pixelSize: 12
    }
  }

  // ethernet ports
  Repeater {
    model: Net.wired

    Section {
      id: wired

      required property var modelData
      readonly property bool up: modelData.state === ConnectionState.Connected

      RowLayout {
        spacing: 10

        Glyph {
          text: Icons.ethernet
          color: wired.up ? Theme.accent : Theme.fg
          font.pixelSize: 18
          Layout.preferredWidth: 26
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
          visible: wired.modelData.hasLink && (wired.up || wired.modelData.network !== null)
          text: wired.up ? "Disconnect" : "Connect"
          onClicked: {
            if (wired.up)
              wired.modelData.disconnect();
            else
              wired.modelData.network.connect();
          }
        }
      }

      ColumnLayout {
        visible: wired.up
        spacing: 4
        Layout.leftMargin: 36

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
      }
    }
  }

  // wifi card, its switch and the network it is on
  Section {
    id: wifi

    readonly property var network: Net.wifiNetwork

    visible: Net.wifi !== null

    RowLayout {
      spacing: 10

      Glyph {
        text: Net.wifiEnabled ? (wifi.network ? Icons.wifi(Net.strength, false) : Icons.wifiFull) : Icons.wifiOff
        color: wifi.network ? Theme.accent : Theme.fg
        font.pixelSize: 18
        Layout.preferredWidth: 26
      }

      ColumnLayout {
        spacing: 0
        Layout.fillWidth: true

        Txt {
          text: "Wi-Fi"
          color: Theme.fgBright
          font.pixelSize: 13
          font.weight: Font.Medium
        }

        Txt {
          font.pixelSize: 12
          elide: Text.ElideRight
          Layout.fillWidth: true
          text: {
            if (!Networking.wifiHardwareEnabled)
              return "Blocked by hardware switch";
            if (!Net.wifiEnabled)
              return "Off";
            return wifi.network ? `Connected to ${wifi.network.name}` : "Not connected";
          }
        }
      }

      Toggle {
        checked: Net.wifiEnabled
        enabled: Networking.wifiHardwareEnabled
        onToggled: Net.toggleWifi()
      }
    }

    ColumnLayout {
      visible: wifi.network !== null
      spacing: 4
      Layout.leftMargin: 36

      ConnInfo {
        id: wifiInfo
        iface: wifi.network ? Net.wifi.name : ""
      }

      InfoRow {
        key: "Signal"
        value: wifi.network ? `${Net.strength}%` : ""
      }
      InfoRow {
        key: "Security"
        value: wifi.network ? Net.securityName(wifi.network) : ""
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

        TextButton {
          text: "Forget"
          onClicked: wifi.network.forget()
        }
      }
    }
  }

  // networks in range
  Section {
    visible: Net.wifi !== null && Net.wifiEnabled
    spacing: 2

    Txt {
      text: "Networks"
      color: Theme.fgBright
      font.pixelSize: 13
      font.weight: Font.Medium
      Layout.leftMargin: 6
      Layout.bottomMargin: 4
    }

    Txt {
      visible: root.others.length === 0
      text: "Searching for networks…"
      font.pixelSize: 12
      Layout.leftMargin: 6
    }

    Repeater {
      model: root.others

      WifiRow {}
    }
  }
}
