import { createBinding, For } from "ags"
import app from "ags/gtk4/app"
import Tray from "gi://AstalTray"

const tray = Tray.get_default()

function TrayButton({ item }: { item: Tray.TrayItem }) {
  if (item.iconThemePath) app.add_icons(item.iconThemePath)

  return (
    <menubutton
      class="tray-item"
      tooltipMarkup={createBinding(item, "tooltipMarkup")((t) => t ?? "")}
      menuModel={createBinding(item, "menuModel")}
      onRealize={(self) => self.insert_action_group("dbusmenu", item.actionGroup)}
    >
      <image gicon={createBinding(item, "gicon")} pixelSize={16} />
    </menubutton>
  )
}

export default function SystemTray() {
  const items = createBinding(tray, "items")

  return (
    <box class="systray" spacing={10}>
      <For each={items}>{(item) => <TrayButton item={item} />}</For>
    </box>
  )
}
