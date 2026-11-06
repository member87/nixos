pragma Singleton

import QtQuick
import Quickshell

// one system menu is open at a time, on the screen named here
Singleton {
  id: root

  // the system menu's tabs, in the rail's order (the wallpaper's stripes,
  // top to bottom); "notifications" is the notification centre
  readonly property var tabs: ["power", "network", "sound", "bluetooth", "nixos"]
  readonly property string defaultTab: "sound"

  property string screen: ""
  property string page: defaultTab
  // a key has moved focus since the popout opened: focus rings show
  property bool keyboard: false

  // the menu's focus grab covers its own bar, so a click on the bar button
  // arrives here instead of dismissing the menu first
  function toggle(screenName: string, pageName: string) {
    // "main" is the bar button: it closes the system menu from any tab and
    // opens it on the default one; from the notification centre it opens
    // the system menu instead. An unknown name opens (or keeps) the default
    // tab; it never closes the menu.
    const main = pageName === "main";
    const known = pageName === "notifications" || tabs.includes(pageName);
    const wanted = known ? pageName : defaultTab;
    if (screen === screenName && ((known && page === wanted) || (main && page !== "notifications"))) {
      close();
      return;
    }
    if (screen === "")
      keyboard = false;
    screen = screenName;
    page = wanted;
  }

  function close() {
    screen = "";
  }
}
