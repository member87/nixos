import app from "ags/gtk4/app"
import { Astal, Gtk } from "ags/gtk4"

export default function DateTimePopup() {
  const { TOP, RIGHT } = Astal.WindowAnchor
  
  return (
    <window
      name="datetime-popup" 
      cssName="datetime-popup"
      visible={false}
      anchor={TOP | RIGHT}
      application={app}
      keymode={Astal.Keymode.ON_DEMAND}
    >
      <box cssName="popup-content" orientation={Gtk.Orientation.VERTICAL} spacing={10}>
        <label label="Calendar & Time" />
        <label label="Today's Date" />
        <button 
          onClicked={() => {
            console.log("Close popup clicked")
            app.get_window("datetime-popup")?.hide()
          }}
        >
          <label label="Close" />
        </button>
      </box>
    </window>
  )
}