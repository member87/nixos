import app from "ags/gtk4/app"
import style from "./style.scss"
import Bar from "./widget/Bar"
import { createSimplePanel } from "./widget/SimplePanel"

app.start({
  css: style,
  main() {
    app.get_monitors().map(Bar)
    createSimplePanel()
  },
})
