import { Astal, Gtk } from "ags/gtk4"
import { execAsync } from "ags/process"

export default function MediaWidget() {
  const togglePlay = () => {
    execAsync("playerctl play-pause").catch(() => {})
  }

  return (
    <box cssName="media" spacing={10}>
      <button onClicked={togglePlay} cssName="media-button">
        <box spacing={5}>
          <label label="▶" />
          <label label="No media playing" />
        </box>
      </button>
    </box>
  )
}