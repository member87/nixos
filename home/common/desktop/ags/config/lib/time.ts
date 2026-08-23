import { createPoll } from "ags/time"
import GLib from "gi://GLib"

const now = createPoll(GLib.DateTime.new_now_local(), 1000, () =>
  GLib.DateTime.new_now_local(),
)

export const time = now((t) => t.format("%H:%M") ?? "")
export const shortDate = now((t) => t.format("%d %b") ?? "")
export const fullDate = now((t) => t.format("%d %b %Y") ?? "")
export const day = now((t) => t.format("%A") ?? "")
