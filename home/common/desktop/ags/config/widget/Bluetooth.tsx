import Bluetooth from "gi://AstalBluetooth";
import { createBinding, createComputed, With } from "gnim";

export function BluetoothIcon() {
  const bluetooth = Bluetooth.get_default();

  const powered = createBinding(bluetooth, "is_powered")

  const icon = createComputed(
    [createBinding(bluetooth, "isConnected"), createBinding(bluetooth, "isPowered")],
    (isConnected, isPowered) => {
    }
  )

  return (
    <box spacing={4}>
      <image />
    </box>
  );
}
