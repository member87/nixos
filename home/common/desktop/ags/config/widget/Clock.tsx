import { time, shortDate } from "../lib/time"

export function Clock() {
  return <label class="clock" label={time} />
}

export function DateLabel() {
  return <label class="date" label={shortDate} />
}
