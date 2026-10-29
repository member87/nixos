import QtQuick

// One view's lyrics for the playing track: asks LyricsStore for them while
// `active` and tracks the line being sung.
QtObject {
  id: root

  property bool active: false
  property string title: ""
  property string artist: ""
  // seconds
  property real length: 0
  property real position: 0

  readonly property var entry: LyricsStore.entries[LyricsStore.key(title, artist, length)] ?? null
  // [{time, text}] by time; empty without synced lyrics
  readonly property var lines: entry?.lines ?? []
  // "loading" | "ready" | "none" | "error"
  readonly property string status: entry?.status ?? "loading"
  // the line being sung, -1 before the first
  readonly property int current: {
    let i = -1;
    // a moment early: the line is on screen as it starts
    while (i + 1 < lines.length && lines[i + 1].time <= position + 0.2)
      i++;
    return i;
  }

  function load() {
    if (active)
      LyricsStore.request(title, artist, length);
  }

  onTitleChanged: Qt.callLater(load)
  onArtistChanged: Qt.callLater(load)
  onLengthChanged: Qt.callLater(load)
  onActiveChanged: Qt.callLater(load)
}
