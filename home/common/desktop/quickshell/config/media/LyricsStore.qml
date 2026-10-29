pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

// Synced lyrics from LRCLIB (lrclib.net: free, no key), one lookup per track
// for every view. LRCLIB often holds several versions of a song; the one with
// timestamps whose length is closest to the player's wins, within
// `tolerance`. A failed lookup is tried again after 3, 10 and 30 seconds
// before it shows as an error; asking again after that starts over.
//
// Results are kept in ~/.cache/quickshell/lyrics.json across restarts, the
// `keep` most recently played songs. A song LRCLIB had no synced lyrics for
// is looked up again after `recheck`, in case they have been added since.
Singleton {
  id: root

  readonly property real tolerance: 8
  readonly property list<int> retries: [3000, 10000, 30000]
  readonly property int keep: 300
  readonly property real recheck: 7 * 24 * 3600 * 1000
  // key -> {status: "loading" | "ready" | "none" | "error", lines: [{time, text}],
  //         checked: when LRCLIB answered, used: when last asked for}
  property var entries: ({})
  // the file must be read before anything is written over it
  property bool restored: false

  function key(title: string, artist: string, length: real): string {
    return title ? `${artist}\n${title}\n${Math.round(length)}` : "";
  }

  function request(title: string, artist: string, length: real) {
    const k = key(title, artist, length);
    if (k === "")
      return;
    const e = entries[k];
    const stale = e?.status === "none" && Date.now() - e.checked > recheck;
    if (e && e.status !== "error" && !stale) {
      // played again: kept in the file a while longer
      if (e.status !== "loading") {
        e.used = Date.now();
        saving.restart();
      }
      return;
    }
    fetch(k, title, artist, length, 0);
  }

  function set(k: string, status: string, lines: var) {
    const now = Date.now();
    const next = Object.assign({}, entries);
    next[k] = {
      status,
      lines,
      checked: now,
      used: now
    };
    entries = next;
    if (status === "ready" || status === "none")
      saving.restart();
  }

  // answers only, newest played first, at most `keep`
  function save() {
    const kept = Object.entries(entries).filter(([, e]) => e.status === "ready" || e.status === "none").sort(([, a], [, b]) => b.used - a.used).slice(0, keep);
    // built by hand: Qt's JavaScript has no Object.fromEntries
    const out = {};
    for (const [k, e] of kept)
      out[k] = e;
    file.setText(JSON.stringify(out));
  }

  function parse(lrc: string): var {
    const out = [];
    const stamp = /\[(\d+):(\d+(?:\.\d+)?)\]/g;
    for (const raw of lrc.split("\n")) {
      const text = raw.replace(/\[[^\]]*\]/g, "").trim();
      stamp.lastIndex = 0;
      let m;
      while ((m = stamp.exec(raw)) !== null)
        out.push({
          time: Number(m[1]) * 60 + Number(m[2]),
          text
        });
    }
    return out.sort((a, b) => a.time - b.time);
  }

  function fetch(k: string, title: string, artist: string, length: real, attempt: int) {
    set(k, "loading", []);
    // Spotify's "Song - Remastered 2011" and "Song (feat. X)" are not in
    // LRCLIB's titles; the first of several artists is
    const track = title.replace(/\s+-\s+.*$/, "").replace(/\s*[([](feat|with)\.?\s[^)\]]*[)\]]/i, "").trim();
    const singer = artist.split(",")[0].trim();
    const xhr = new XMLHttpRequest();
    xhr.open("GET", `https://lrclib.net/api/search?track_name=${encodeURIComponent(track)}&artist_name=${encodeURIComponent(singer)}`);
    // LRCLIB asks clients to name themselves; XHR may not set User-Agent
    xhr.setRequestHeader("Lrclib-Client", "quickshell-bar");
    xhr.onreadystatechange = () => {
      if (xhr.readyState !== XMLHttpRequest.DONE)
        return;
      if (xhr.status !== 200) {
        console.warn(`lyrics: LRCLIB answered ${xhr.status || "nothing"} for "${track}" by ${singer}, attempt ${attempt + 1}`);
        if (attempt < root.retries.length)
          later.createObject(root, {
            interval: root.retries[attempt],
            run: () => root.fetch(k, title, artist, length, attempt + 1)
          });
        else
          root.set(k, "error", []);
        return;
      }
      let found = [];
      try {
        const best = JSON.parse(xhr.responseText).filter(r => r.syncedLyrics && (length <= 0 || Math.abs(r.duration - length) <= root.tolerance)).sort((a, b) => Math.abs(a.duration - length) - Math.abs(b.duration - length))[0];
        if (best)
          found = root.parse(best.syncedLyrics);
      } catch (e) {}
      root.set(k, found.length > 0 ? "ready" : "none", found);
    };
    xhr.send();
  }

  // one retry, then gone
  Component {
    id: later

    Timer {
      property var run
      running: true
      onTriggered: {
        run();
        destroy();
      }
    }
  }

  // a few plays or answers in a row, one write
  Timer {
    id: saving
    interval: 5000
    onTriggered: {
      if (root.restored)
        root.save();
    }
  }

  FileView {
    id: file
    path: Paths.lyrics
    blockLoading: true
    printErrors: false
    atomicWrites: true

    onLoaded: {
      try {
        // what this run already looked up is newer
        root.entries = Object.assign(JSON.parse(text()), root.entries);
      } catch (e) {}
      root.restored = true;
    }
    // first run: nothing saved yet
    onLoadFailed: root.restored = true
  }
}
