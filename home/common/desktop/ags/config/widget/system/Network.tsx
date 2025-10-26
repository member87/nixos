import Network from "gi://AstalNetwork";
import { createBinding, With } from "ags";

export function SystemNetwork() {

  const network = Network.get_default();
  network.wifi.activeAccessPoint

  const iconBinding = createBinding(network.wifi, "iconName");
  const ssid = createBinding(network.wifi, "ssid");
  const enabled = createBinding(network.wifi, "enabled")

  return (
    <box spacing={4} class={`${enabled ? 'enabled' : 'disabled'}`}>
      <image iconName={iconBinding} />

      <With value={ssid}>
        {(name) => name
          ? <label label={name} />
          : <label label={"Not Connected"} />
        }

      </With>
    </box>
  );
}
