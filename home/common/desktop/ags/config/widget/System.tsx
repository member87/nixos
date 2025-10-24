import { BatteryIcon } from "./Battery";
import { BluetoothIcon } from "./Bluetooth";
import { NetworkIcon } from "./Network";

export function System() {


  return <box>
    <BluetoothIcon />
    <NetworkIcon />
    <BatteryIcon />
  </box>
}
