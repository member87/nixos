import { createBinding } from "ags"
import Battery from "gi://AstalBattery"

export function BatteryIcon() {

  const battery = Battery.get_default()

  print(battery.get_icon_name())

  return <box visible={createBinding(battery, "is_present")}>
    <image iconName={createBinding(battery, "iconName")} />
  </box>

}
