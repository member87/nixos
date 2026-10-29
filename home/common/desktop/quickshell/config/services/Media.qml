pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
  id: root

  // only Spotify: browser tabs, Discord and other MPRIS players are ignored
  // by the bar and the menu's media panel
  readonly property var player: Mpris.players.values.find(p => p.dbusName.toLowerCase().includes("spotify")) ?? null

  // The track changed before the last one played to its end: a skip (next,
  // previous, or another song picked), from anywhere: the bar, the keys,
  // Spotify itself. A song that ends and leads into the next is not one.
  signal skipped

  // seconds before the end inside which a change counts as the song ending
  readonly property real ending: 4
  // where the playing track was at the last look: {position, length, at, playing}
  property var last: null
  // when the track last changed, 0 before the first change seen
  property real changedAt: 0
  property bool pendingSkip: false

  function sample() {
    if (!player || !player.lengthSupported || player.length <= 0)
      return;
    player.positionChanged();
    // just after a change some players still report the old track's place
    if (player.position > player.length)
      return;
    last = {
      position: player.position,
      length: player.length,
      at: Date.now(),
      playing: player.isPlaying
    };
  }

  onPlayerChanged: {
    last = null;
    changedAt = 0;
    Qt.callLater(sample);
  }

  Timer {
    interval: 500
    repeat: true
    running: root.player?.isPlaying ?? false
    triggeredOnStart: true
    onTriggered: root.sample()
  }

  // the first look at a new track, once it has settled
  Timer {
    id: settle
    interval: 300
    onTriggered: root.sample()
  }

  Connections {
    target: root.player

    function onTrackChanged() {
      const l = root.last;
      const now = Date.now();
      root.last = null;
      if (l) {
        const reached = l.position + (l.playing ? (now - l.at) / 1000 : 0);
        root.pendingSkip = l.length - reached > root.ending;
      } else {
        // no look at the old track: skipped within moments of the change
        // before it; with no change before it, Spotify loading its first
        root.pendingSkip = root.changedAt > 0 && now - root.changedAt < 5000;
      }
      root.changedAt = now;
    }

    // the new track's title and artist are in
    function onPostTrackChanged() {
      if (root.pendingSkip) {
        root.pendingSkip = false;
        root.skipped();
      }
      settle.restart();
    }

    // the place a pause leaves it at
    function onIsPlayingChanged() {
      root.sample();
    }
  }
}
