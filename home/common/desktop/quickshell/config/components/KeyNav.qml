import QtQuick
import QtQuick.Window
import qs.services

// Keyboard control for a popout: the arrows and Tab walk its controls in
// reading order (wrapping at the ends), Enter or Space presses the one in
// focus, Escape leaves (`cancelled`). The first key also turns on the focus ring, which
// stays off for the pointer. Put the popout's content inside; `flick`
// scrolls to keep the focused control in view.
FocusScope {
  id: root

  property Flickable flick: null
  // Left and Right walk too, unless a control in focus takes them (a
  // slider) or the popout wants them: Left is then `back` (out of a submenu)
  property bool arrowsSideways: true
  signal cancelled
  signal back

  function inside(item: Item): bool {
    for (let i = item; i; i = i.parent)
      if (i === root)
        return true;
    return false;
  }

  function step(forward: bool) {
    Menus.keyboard = true;
    const from = Window.activeFocusItem && inside(Window.activeFocusItem) ? Window.activeFocusItem : root;
    let next = from.nextItemInFocusChain(forward);
    // a chain that runs out of the popout comes back in at the other end
    for (let guard = 0; next && !inside(next) && guard < 200; guard++)
      next = next.nextItemInFocusChain(forward);
    if (!next || next === root)
      return;
    next.forceActiveFocus(forward ? Qt.TabFocusReason : Qt.BacktabFocusReason);
    reveal(next);
  }

  function reveal(item: Item) {
    if (!flick)
      return;
    const y = item.mapToItem(flick.contentItem, 0, 0).y;
    const pad = 8;
    if (y < flick.contentY)
      flick.contentY = Math.max(0, y - pad);
    else if (y + item.height > flick.contentY + flick.height)
      flick.contentY = Math.min(flick.contentHeight - flick.height, y + item.height - flick.height + pad);
  }

  Keys.onPressed: e => {
    switch (e.key) {
    case Qt.Key_Escape:
      root.cancelled();
      break;
    case Qt.Key_Tab:
    case Qt.Key_Down:
      root.step(true);
      break;
    case Qt.Key_Backtab:
    case Qt.Key_Up:
      root.step(false);
      break;
    case Qt.Key_Right:
      if (!root.arrowsSideways)
        return;
      root.step(true);
      break;
    case Qt.Key_Left:
      if (!root.arrowsSideways) {
        root.back();
        break;
      }
      root.step(false);
      break;
    default:
      return;
    }
    e.accepted = true;
  }
}
