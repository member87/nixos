import Network from "gi://AstalNetwork";
import { createBinding, With } from "ags";

export function NetworkSSID() {
  const network = Network.get_default();

  const primary = createBinding(network, "primary")

  const mappings = {
    [Network.Primary.WIRED]: <Wired />,
    [Network.Primary.WIFI]: <Wifi />
  }

  return (
    <box cssClasses={["wifi"]} spacing={4}>
      <With value={primary}>
        {(state) => mappings[state]}
      </With>
    </box>
  );
}

function Wifi() {
  const network = Network.get_default();
  const iconBinding = createBinding(network.wifi, "iconName");

  return <image iconName={iconBinding} />
}

function Wired() {
  const network = Network.get_default();
  const iconBinding = createBinding(network.wired, "iconName");

  return <image iconName={iconBinding} />
}
