pragma Singleton

import QtQuick
import Quickshell

// one system menu is open at a time, on the screen named here
Singleton {
  id: root

  property string screen: ""
  property string page: "main"
  property real closedAt: 0

  function toggle(screenName: string, pageName: string) {
    // the click that dismissed the popup also lands on the bar button;
    // do not reopen what that same click just closed
    if (screen === "" && Date.now() - closedAt < 250)
      return;
    // the bar button (page "main") closes the menu from any page
    if (screen === screenName && (page === pageName || pageName === "main")) {
      close();
      return;
    }
    screen = screenName;
    page = pageName;
  }

  function close() {
    if (screen !== "")
      closedAt = Date.now();
    screen = "";
  }
}
