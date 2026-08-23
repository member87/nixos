import { createBinding, createComputed, For } from "ags"
import { Gtk } from "ags/gtk4"
import Hyprland from "gi://AstalHyprland"
import type Gdk from "gi://Gdk?version=4.0"

const hyprland = Hyprland.get_default()
const focusedWorkspaceId = createBinding(hyprland, "focusedWorkspace", "id")

const WORKSPACE_IDS = Array.from({ length: 10 }, (_, i) => i + 1)

function WorkspaceButton({
  id,
  workspace,
}: {
  id: number
  workspace: Hyprland.Workspace | undefined
}) {
  const clients = workspace ? createBinding(workspace, "clients") : null
  const active = createComputed(() => focusedWorkspaceId() === id)

  const classes = active((isActive) => {
    const occupied = clients ? clients().length > 0 : false
    const list = ["workspace-entry", occupied ? "occupied" : "empty"]
    if (isActive) list.push("workspace-selected")
    return list
  })

  function onClicked() {
    if (workspace) workspace.focus()
    else hyprland.dispatch("workspace", `${id}`)
  }

  return (
    <button cssClasses={classes} onClicked={onClicked}>
      {/* fixed-size circle with the digit overlaid: GtkOverlay sizes from its
          main child only, so the label's ~16px line box can not inflate the
          circle no matter the font size (GTK CSS has no max-height) */}
      <overlay>
        <box class="circle" halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER} />
        <label $type="overlay" label={`${id}`} halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER} />
      </overlay>
    </button>
  )
}

export default function Workspaces({ gdkmonitor: _gdkmonitor }: { gdkmonitor: Gdk.Monitor }) {
  const workspaceMap = createBinding(hyprland, "workspaces")((all) => {
    const map = new Map<number, Hyprland.Workspace>()
    for (const ws of all) map.set(ws.id, ws)
    return map
  })

  function onScroll(_self: Gtk.EventControllerScroll, _dx: number, dy: number) {
    hyprland.dispatch("workspace", dy > 0 ? "+1" : "-1")
  }
  return (
    <box class="workspaces-widget">
      <Gtk.EventControllerScroll
        flags={Gtk.EventControllerScrollFlags.VERTICAL}
        onScroll={onScroll}
      />
      <box class="workspace-wrapper" spacing={2}>
        <For each={workspaceMap((m) => WORKSPACE_IDS.map((id) => [id, m.get(id)] as const))}>
          {([id, workspace]) => <WorkspaceButton id={id} workspace={workspace} />}
        </For>
      </box>
    </box>
  )
}
