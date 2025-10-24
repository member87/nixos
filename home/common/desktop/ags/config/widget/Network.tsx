import Network from "gi://AstalNetwork";
import { createBinding } from "gnim";

export function NetworkIcon() {
  const network = Network.get_default();

  const iconBinding = createBinding(network.wifi, "iconName");
  console.log(iconBinding)

  return (
    <box cssClasses={["wifi"]} spacing={4}>
      <image iconName={iconBinding} />
    </box>
  );
}
