import { Accessor } from "ags"
import { Gtk } from "ags/gtk4"
import Gdk from "gi://Gdk?version=4.0"
import GdkPixbuf from "gi://GdkPixbuf?version=2.0"

type Props = {
  /** local path to the image - reactive (AstalMpris coverArt accessor) or static */
  path: Accessor<string> | string
  /** clip to a circle (bar art). mutually exclusive with `radius` */
  circle?: boolean
  /** clip to a rounded rectangle with this corner radius (popover bg) */
  radius?: number
  /** 0..1 black overlay drawn over the image for text contrast */
  scrim?: number
  /** natural content size for standalone use; omit (1x1 + expand) to fill a parent */
  width?: number
  height?: number
  /** expand to fill the parent (background use) */
  hexpand?: boolean
  vexpand?: boolean
}

/**
 * GTK4 CSS border-radius does not clip Gtk.Image textures, so album art can
 * not be rounded or full-bleed through CSS alone. This draws the pixbuf with
 * cairo, scaled to cover the allocation and clipped to a circle or rounded
 * rectangle.
 *
 * `path` may be an Accessor; it reloads the pixbuf in place on change. Do NOT
 * wrap this in <With> to react to path changes - With removes and re-appends
 * its child at the END of the parent box, which reorders the art after any
 * sibling text that was there from the start.
 */
export default function CoverArt({
  path,
  circle,
  radius = 0,
  scrim = 0,
  width,
  height,
  hexpand,
  vexpand,
}: Props) {
  const area = new Gtk.DrawingArea()

  let pixbuf: GdkPixbuf.Pixbuf | null = null
  const load = (p: string | null | undefined) => {
    try {
      pixbuf = p ? GdkPixbuf.Pixbuf.new_from_file(p) : null
    } catch {
      pixbuf = null
    }
    area.queue_draw()
  }

  if (path instanceof Accessor) {
    load(path())
    const dispose = path.subscribe(() => load(path()))
    area.connect("destroy", () => dispose())
  } else {
    load(path)
  }

  if (width) area.set_content_width(width)
  if (height) area.set_content_height(height)
  if (hexpand) area.set_hexpand(true)
  if (vexpand) area.set_vexpand(true)

  area.set_draw_func((_area, cr, w, h) => {
    try {
      if (pixbuf && w > 0 && h > 0) {
        // scale-to-cover, centered
        const s = Math.max(w / pixbuf.get_width(), h / pixbuf.get_height())
        const dw = pixbuf.get_width() * s
        const dh = pixbuf.get_height() * s

        cr.save()

        if (circle) {
          cr.arc(w / 2, h / 2, Math.min(w, h) / 2, 0, 2 * Math.PI)
          cr.clip()
        } else if (radius > 0) {
          const r = Math.min(radius, w / 2, h / 2)
          cr.newSubPath()
          cr.arc(w - r, h - r, r, 0, Math.PI / 2)
          cr.arc(r, h - r, r, Math.PI / 2, Math.PI)
          cr.arc(r, r, r, Math.PI, (3 * Math.PI) / 2)
          cr.arc(w - r, r, r, (3 * Math.PI) / 2, 2 * Math.PI)
          cr.closePath()
          cr.clip()
        }

        cr.save()
        cr.scale(s, s)
        Gdk.cairo_set_source_pixbuf(
          cr,
          pixbuf,
          (w - dw) / 2 / s,
          (h - dh) / 2 / s,
        )
        cr.paint()
        cr.restore()

        if (scrim > 0) {
          cr.setSourceRGBA(0, 0, 0, scrim)
          cr.rectangle(0, 0, w, h)
          cr.fill()
        }

        cr.restore()
      }
    } finally {
      // GJS requires manual disposal of cairo contexts handed to callbacks
      cr.$dispose()
    }
  })

  return area
}
