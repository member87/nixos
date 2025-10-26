import { BatteryIcon } from "./Battery";
import { BluetoothIcon } from "./Bluetooth";
import { NetworkIcon } from "./Network";
import { useSimplePanel } from "./SimplePanel";

export function System() {
  const panel = useSimplePanel();

  return (
    <button
      cssClasses={["system-button"]}
      onClicked={() => panel.toggle()}
    >
      <box spacing={8}>
        <BluetoothIcon />
        <NetworkIcon />
        <BatteryIcon />
      </box>
    </button>
  );
}
