import { createPoll } from "ags/time"

export default function DateTime() {
  const now = createPoll("", 1000, () => new Date().toLocaleTimeString('en-GB', {
    hour: '2-digit',
    minute: '2-digit',
  }))


  return (
    <box>
      <label label={now} />
    </box>
  )
}
