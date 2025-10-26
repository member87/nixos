import Bluetooth from "gi://AstalBluetooth";
import { createBinding } from "ags";

export function BluetoothIcon() {
  const bluetooth = Bluetooth.get_default();

  return (
    <box cssClasses={["bluetooth"]} spacing={4}>
      <image iconName="bluetooth-active-symbolic" />
    </box>
  );
}
