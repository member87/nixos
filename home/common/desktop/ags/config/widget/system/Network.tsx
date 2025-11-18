import Network from "gi://AstalNetwork";
import { createBinding, With } from "ags";
import { NetworkIcon } from "../network/network-icon";

export function SystemNetwork() {

  const network = Network.get_default();
  network.wifi.activeAccessPoint

  const ssid = createBinding(network.wifi, "ssid");
  const wifiEnabled = createBinding(network.wifi, "enabled");
  const wifiIconName = createBinding(network.wifi, "iconName");

  return (

    <box
      spacing={6}
      hexpand={true}
      cssClasses={wifiEnabled.as(enabled => enabled ? ["wifi-item", "active"] : ["wifi-item"])}
    >
      <NetworkIcon />

      <With value={ssid}>
        {(name) => name
          ? <label label={name} />
          : <label label={"Not Connected"} />
        }

      </With>

    </box>
  );
}
