import { createPoll } from "ags/time"
import type { Accessor } from "ags"

export type VpnState = { connected: boolean; ip: string }

const GET_PROTON0_IP = [
  "bash",
  "-c",
  "ip -o -4 addr show proton0 2>/dev/null | awk '{print $4}' | cut -d/ -f1",
]

export const vpn: Accessor<VpnState> = createPoll(
  { connected: false, ip: "" },
  5000,
  GET_PROTON0_IP,
  (stdout) => {
    const ip = stdout.trim()
    return ip ? { connected: true, ip } : { connected: false, ip: "" }
  },
)
