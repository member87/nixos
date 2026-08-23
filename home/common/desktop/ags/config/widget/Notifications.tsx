import { With } from "ags"
import { createSubprocess, execAsync } from "ags/process"
import { NOTIFICATION_ICON } from "../lib/icons"

type SwayncState = { count: number; dnd: boolean }

const swaync = createSubprocess<SwayncState>(
  { count: 0, dnd: false },
  ["swaync-client", "--subscribe-waybar"],
  (line, prev) => {
    try {
      const { text, class: cls } = JSON.parse(line)
      return { count: Number(text) || 0, dnd: cls === "dnd" }
    } catch {
      return prev
    }
  },
)

export default function Notifications() {
  return (
    <button
      class="notifications-container"
      onClicked={() => execAsync(["swaync-client", "-t"]).catch(console.error)}
    >
      <box spacing={4}>
        <label class="icon" label={NOTIFICATION_ICON} />
        <With value={swaync}>
          {(s) => s.count > 0 && <label class="notification-count" label={`${s.count}`} />}
        </With>
      </box>
    </button>
  )
}
