import { createBinding, With } from "ags"
import Hyprland from "gi://AstalHyprland"

export default function Workspaces() {
  const hyprland = Hyprland.get_default()

  const focusedWorkspace = createBinding(hyprland, "focusedWorkspace")

  return (
    <box class="workspaces" spacing={5}>
      <With value={focusedWorkspace}>
        {(workspace) => (
          <box spacing={5}>
            {Array.from({ length: 10 }, (_, i) => {
              const workspaceId = i + 1
              const isActive = workspace?.get_id() === workspaceId

              return (
                <button
                  onClicked={() => hyprland.dispatch("workspace", workspaceId.toString())}
                  class={`workspace ${isActive ? "active" : ""}`}
                >
                </button>
              )
            })}
          </box>
        )}
      </With>
    </box>
  )
}
