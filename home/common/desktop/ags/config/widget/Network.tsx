import Network from "gi://AstalNetwork";
import { createBinding } from "gnim";

export function NetworkIcon() {
  const network = Network.get_default();



  return (
    <box cssClasses={["wifi"]} spacing={4}>
      <image iconName={createBinding(network.wifi, "icon_name")} />
    </box>
  );
}
