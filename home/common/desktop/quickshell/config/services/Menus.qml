pragma Singleton

import QtQuick
import Quickshell

// one system menu is open at a time, on the screen named here
Singleton {
  id: root

  property string screen: ""
  property string page: "main"
  // a key has moved focus since the popout opened: focus rings show
  property bool keyboard: false

  // the menu's focus grab covers its own bar, so a click on the bar button
  // arrives here instead of dismissing the menu first
  function toggle(screenName: string, pageName: string) {
    // the bar button (page "main") closes the system menu from any of its
    // pages; from the notification centre it opens the system menu instead
    if (screen === screenName && (page === pageName || (pageName === "main" && page !== "notifications"))) {
      close();
      return;
    }
    if (screen === "")
      keyboard = false;
    screen = screenName;
    page = pageName;
  }

  function close() {
    screen = "";
  }
}
