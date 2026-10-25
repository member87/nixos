pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.common
import Quickshell.Services.Notifications

// The notification daemon (org.freedesktop.Notifications), replacing swaync.
//
// The history is a list of entries, newest first. An entry is a plain copy of
// a notification (app, summary, body, icon, urgency, arrival time) plus the
// live Notification while its app still holds it, which is what carries the
// actions. The copies are saved to $XDG_STATE_HOME/quickshell/notifications.json,
// so the history survives a restart (without actions: those die with the app's
// connection) and the lock screen can count what arrived while locked.
Singleton {
  id: root

  readonly property string file: Paths.notifications
  readonly property int keep: 100

  // {key, live, appName, appIcon, image, summary, body, urgency, time}
  property var entries: []
  readonly property int count: entries.length
  // live notifications on screen as popups, newest first
  property var popups: []

  // newest first, one group per app, ordered by each app's newest entry
  readonly property var groups: {
    const byApp = new Map();
    for (const e of entries) {
      const app = e.appName || "Notification";
      if (!byApp.has(app))
        byApp.set(app, []);
      byApp.get(app).push(e);
    }
    return [...byApp].map(([app, items]) => ({
          app,
          items
        }));
  }

  function age(e: var): string {
    const minutes = Math.floor((Time.now - e.time) / 60000);
    if (minutes < 1)
      return "now";
    if (minutes < 60)
      return `${minutes}m`;
    const hours = Math.floor(minutes / 60);
    return hours < 24 ? `${hours}h` : `${Math.floor(hours / 24)}d`;
  }

  function toggleDoNotDisturb() {
    UiState.doNotDisturb = !UiState.doNotDisturb;
    if (UiState.doNotDisturb)
      popups = popups.filter(n => n.urgency === NotificationUrgency.Critical);
  }

  function entryOf(n: var): var {
    return entries.find(e => e.live === n) ?? null;
  }

  // the popup timed out or was closed; the entry stays in the history unless
  // the notification asked not to be kept (transient)
  function hidePopup(n: var) {
    popups = popups.filter(p => p !== n);
    if (n.transient)
      n.expire();
  }

  function dismiss(e: var) {
    entries = entries.filter(x => x !== e);
    if (e.live) {
      popups = popups.filter(p => p !== e.live);
      e.live.dismiss();
    }
  }

  function dismissGroup(app: string) {
    for (const e of entries.filter(x => (x.appName || "Notification") === app))
      dismiss(e);
  }

  function clearAll() {
    for (const e of [...entries])
      dismiss(e);
  }

  // the default action if the app is still there; the click means "seen"
  function activate(e: var) {
    const action = e.live?.actions.find(a => a.identifier === "default");
    if (action)
      action.invoke();
    dismiss(e);
  }

  // one-time codes ("Your code is 482913") get a copy button, as swaync's
  // notification-2fa-action did
  function code(e: var): string {
    const text = `${e.summary} ${e.body}`;
    if (!/\b(code|otp|pin|verif|passcode|2fa|one[- ]time)/i.test(text))
      return "";
    const m = text.match(/\b(\d{4,8})\b/);
    return m ? m[1] : "";
  }

  function copy(text: string) {
    Quickshell.execDetached(["wl-copy", text]);
  }

  // image data sent inline (image://) cannot outlive this process
  function keepable(path: string): string {
    return path.startsWith("/") || path.startsWith("file:") ? path : "";
  }

  function save() {
    const plain = entries.map(e => ({
          appName: e.appName,
          appIcon: e.appIcon,
          image: keepable(e.image),
          summary: e.summary,
          body: e.body,
          urgency: e.urgency,
          time: e.time
        }));
    store.setText(JSON.stringify(plain));
  }

  // an app replacing its notification (a music player's "now playing")
  // updates the live object; copy it into the entry
  function refresh(n: var) {
    entries = entries.map(e => e.live !== n ? e : Object.assign({}, e, {
          appName: n.appName,
          appIcon: n.appIcon,
          image: n.image,
          summary: n.summary,
          body: n.body,
          urgency: n.urgency
        }));
  }

  // the initial empty list must not overwrite the file before it is read
  property bool restored: false
  onEntriesChanged: {
    if (restored)
      save();
  }

  NotificationServer {
    id: server

    // a reload starts from the saved history instead
    keepOnReload: false
    persistenceSupported: true
    bodySupported: true
    bodyMarkupSupported: true
    bodyHyperlinksSupported: true
    actionsSupported: true
    imageSupported: true

    onNotification: n => {
      n.tracked = true;
      const entry = {
        key: `${n.id}-${Date.now()}`,
        live: n,
        appName: n.appName,
        appIcon: n.appIcon,
        image: n.image,
        summary: n.summary,
        body: n.body,
        urgency: n.urgency,
        time: Date.now()
      };
      root.entries = [entry, ...root.entries].slice(0, root.keep);

      n.summaryChanged.connect(() => root.refresh(n));
      n.bodyChanged.connect(() => root.refresh(n));
      // closed by its app or expired: gone from popups and history
      n.closed.connect(reason => {
        root.popups = root.popups.filter(p => p !== n);
        if (reason !== NotificationCloseReason.Dismissed)
          root.entries = root.entries.filter(e => e.live !== n);
      });

      if (!UiState.doNotDisturb || n.urgency === NotificationUrgency.Critical)
        root.popups = [n, ...root.popups];
    }
  }

  FileView {
    id: store
    path: root.file
    blockLoading: true
    printErrors: false
    atomicWrites: true

    onLoaded: {
      try {
        const saved = JSON.parse(text());
        // anything that arrived before the file was read is newer
        root.entries = [...root.entries, ...saved.map((e, i) => Object.assign({
                key: `saved-${i}-${e.time}`,
                live: null
              }, e))].slice(0, root.keep);
      } catch (e) {}
      root.restored = true;
    }
    // first run: nothing saved yet
    onLoadFailed: root.restored = true
  }
}
