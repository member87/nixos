import QtQuick
import Quickshell
import qs.common

// A popup hung from the bar's bottom edge under `target` (an item in the
// bar), drawn as a BarDrawer. Size it with panelWidth/panelHeight; children
// go in the panel. It slides out of the bar each time it opens.
PopupWindow {
  id: root

  required property Item target
  default property alias content: drawer.content
  property real panelWidth: 200
  property real panelHeight: 100
  readonly property alias drawer: drawer

  // the target's top in the bar window: the anchor rect is moved up to the
  // bar's top edge so the popup hangs from the bar, not from the target.
  // Reads y/height so it follows layout changes.
  readonly property real targetTop: {
    target.y;
    target.height;
    target.parent?.y;
    return target.mapToItem(null, 0, 0).y;
  }

  anchor.item: target
  anchor.rect.x: 0
  anchor.rect.y: -Math.round(targetTop)
  anchor.rect.width: target.width
  // one short of the bar: the popup starts on the bar's bottom line and
  // covers it where they join
  anchor.rect.height: Theme.barHeight - 1
  anchor.edges: Edges.Bottom
  anchor.gravity: Edges.Bottom
  anchor.adjustment: PopupAdjustment.Slide
  color: "transparent"
  implicitWidth: panelWidth + drawer.ear * 2
  implicitHeight: panelHeight
  mask: Region {
    item: drawer.area
  }

  onVisibleChanged: {
    if (visible)
      drawer.slide();
  }

  BarDrawer {
    id: drawer
  }
}
