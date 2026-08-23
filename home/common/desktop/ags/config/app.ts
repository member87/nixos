import app from "ags/gtk4/app"
import Gtk from "gi://Gtk?version=4.0"
import { intrinsicElements } from "gnim/gtk4/jsx-runtime"
import style from "./style.scss"
import Bar from "./widget/Bar"

// ags' jsx-runtime registers a fixed set of widgets; Gtk.ProgressBar is not
// among them (Gtk.LevelBar is, but its block requisition ignores CSS
// min-height, so the battery bar can not be slimmed that way).
Object.assign(intrinsicElements, { progressbar: Gtk.ProgressBar })
app.start({
  instanceName: "ags",
  css: style,
  main() {
    app.get_monitors().forEach(Bar)
  },
})
