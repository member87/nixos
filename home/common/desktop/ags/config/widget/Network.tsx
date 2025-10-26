import Network from "gi://AstalNetwork";
import { createBinding } from "ags";

export function NetworkIcon() {
  const network = Network.get_default();

  const iconBinding = createBinding(network.wifi, "iconName");

  return (
    <box cssClasses={["wifi"]} spacing={4}>
      <image iconName={iconBinding} />
    </box>
  );
}
