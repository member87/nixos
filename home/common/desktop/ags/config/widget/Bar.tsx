import app from "ags/gtk4/app"
import { Astal, Gtk } from "ags/gtk4"
import type Gdk from "gi://Gdk?version=4.0"

import Workspaces from "./Workspaces"
import Music from "./Music"
import SystemTray from "./SystemTray"
import Indicators from "./Indicators"
import Notifications from "./Notifications"
import { Clock, DateLabel } from "./Clock"

export default function Bar(gdkmonitor: Gdk.Monitor) {
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

  return (
    <window
      visible
      name={`bar-${gdkmonitor.get_connector()}`}
      class="Bar"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={TOP | LEFT | RIGHT}
      application={app}
    >
      <centerbox cssName="centerbox">
        <box $type="start">
          <Workspaces gdkmonitor={gdkmonitor} />
        </box>
        <box $type="center">
          <Music />
        </box>
        <box $type="end" halign={Gtk.Align.END} spacing={4}>
          <SystemTray />
          <Indicators />
          <Notifications />
          <Clock />
          <DateLabel />
        </box>
      </centerbox>
    </window>
  )
}
