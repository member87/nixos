import { createBinding, createComputed, With } from "ags"
import Pango from "gi://Pango?version=1.0"
import Mpris from "gi://AstalMpris"
import CoverArt from "./CoverArt"

const mpris = Mpris.get_default()

function Player({ player }: { player: Mpris.Player }) {
  const title = createBinding(player, "title")
  const artist = createBinding(player, "artist")
  const coverArt = createBinding(player, "coverArt")

  // single combined label: separate title/artist labels accumulate their own
  // padding plus box spacing into a wide gap around the dash
  const text = createComputed(() => {
    const t = title() ?? ""
    const a = artist()
    return a ? `${t} - ${a}` : t
  })

  return (
    <box class="music" spacing={4}>
      {/* CoverArt reloads in place on track change - keep it as the FIRST
          child (before the labels) and do not wrap it in <With>, which
          re-appends children at the end of the box */}
      <CoverArt path={coverArt} circle width={20} height={20} />
      <label label={text} maxWidthChars={40} ellipsize={Pango.EllipsizeMode.END} />
    </box>
  )
}

export default function Music() {
  const player = createBinding(mpris, "players")((players) => players[0] ?? null)

  return (
    <box>
      <With value={player}>{(p) => p && <Player player={p} />}</With>
    </box>
  )
}
