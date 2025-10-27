import { createBinding, With } from "ags";
import Bluetooth from "gi://AstalBluetooth";

export function SystemBluetooth() {


  const bluetooth = Bluetooth.get_default();

  const bluetoothEnabled = createBinding(bluetooth, "isPowered");

  return (

    <box
      spacing={4}
      hexpand={true}
      cssClasses={bluetoothEnabled.as(enabled => enabled ? ["bluetooth-item", "active"] : ["bluetooth-item"])}
    >
      <image iconName="bluetooth-active-symbolic" />
    </box>
  );
}
