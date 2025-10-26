import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import Workspaces from "./Workspaces"
import MediaWidget from "./MediaWidget"
import DateTime from "./DateTime"
import { BatteryIcon } from "./Battery"
import { System } from "./System"

export default function Bar(gdkmonitor: Gdk.Monitor) {
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

  return (
    <window
      visible
      name="bar"
      cssName="Bar"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={TOP | LEFT | RIGHT}
      application={app}
    >
      <box cssName="bar-content" orientation={Gtk.Orientation.HORIZONTAL}>
        <box halign={Gtk.Align.START} cssName="left-section" hexpand>
          <Workspaces />
        </box>

        <box halign={Gtk.Align.END} cssName="right-section" hexpand spacing={8}>
          <System />
          <DateTime />
        </box>
      </box>
    </window>
  )
}
