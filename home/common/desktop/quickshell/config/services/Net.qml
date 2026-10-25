pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking
import qs.common

Singleton {
  id: root

  readonly property var devices: Networking.devices.values.filter(d => d.nmManaged)
  // a host may have no wifi card (odin) or no ethernet port in use (thor)
  readonly property var wifi: devices.find(d => d.type === DeviceType.Wifi) ?? null
  readonly property var wired: devices.filter(d => d.type === DeviceType.Wired)
  readonly property var wiredActive: wired.find(d => d.connected) ?? null
  readonly property var wifiNetworks: wifi ? wifi.networks.values : []
  readonly property var wifiNetwork: wifiNetworks.find(n => n.connected) ?? null

  readonly property bool wifiEnabled: Networking.wifiEnabled
  readonly property bool connected: wiredActive !== null || wifiNetwork !== null
  readonly property int strength: Math.round((wifiNetwork?.signalStrength ?? 0) * 100)

  readonly property string icon: {
    if (wiredActive)
      return Icons.ethernet;
    if (wifiNetwork)
      return Icons.wifi(strength, false);
    return Icons.wifiOff;
  }

  readonly property string label: {
    if (wiredActive)
      return "Ethernet";
    if (wifiNetwork)
      return wifiNetwork.name;
    return wifi && wifiEnabled ? "Not Connected" : "WiFi";
  }

  function secured(network: var): bool {
    return network.security !== WifiSecurityType.Open && network.security !== WifiSecurityType.Owe;
  }

  // the bar can only supply a pre-shared key; 802.1X needs a full editor
  function needsPassword(network: var): bool {
    const s = network.security;
    return s === WifiSecurityType.WpaPsk || s === WifiSecurityType.Wpa2Psk || s === WifiSecurityType.Sae;
  }

  function securityName(network: var): string {
    switch (network.security) {
    case WifiSecurityType.Open:
      return "Open";
    case WifiSecurityType.Owe:
      return "Enhanced Open";
    case WifiSecurityType.WpaPsk:
      return "WPA";
    case WifiSecurityType.Wpa2Psk:
      return "WPA2";
    case WifiSecurityType.Sae:
      return "WPA3";
    case WifiSecurityType.Wpa2Eap:
    case WifiSecurityType.WpaEap:
    case WifiSecurityType.Wpa3SuiteB192:
      return "Enterprise";
    case WifiSecurityType.StaticWep:
    case WifiSecurityType.DynamicWep:
      return "WEP";
    default:
      return "Secured";
    }
  }

  function toggleWifi() {
    Networking.wifiEnabled = !Networking.wifiEnabled;
  }
}
