pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// What Spotify plays next and which tracks are liked, from the Spotify Web
// API, for the music drawer. The sign-in and the refresh token stay in
// bar-spotify (home/common/desktop/quickshell); this asks it for short-lived
// access tokens. Spotify is only asked while the drawer is open (`watched`)
// and when it opens; a track change while it is closed moves the queue up
// one place here, and the next opening checks it.
Singleton {
  id: root

  // "idle" before the first look, "off" without a client ID (default.nix),
  // "unlinked", "linking" while the browser sign-in runs, "loading",
  // "ready", "error" when Spotify could not be reached
  property string status: "idle"
  // the drawer is open
  property bool watched: false
  // the tracks after the playing one: [{uri, title, artist, length, art}]
  property var queue: []
  // the queue was fetched at least once since the last sign-in
  property bool queueKnown: false
  // uri -> true / false, for the tracks asked about so far
  property var liked: ({})
  // the playing track's URI, from Spotify's MPRIS metadata
  readonly property string current: {
    const id = Media.player?.metadata?.["mpris:trackid"] ?? "";
    // "/com/spotify/track/<id>" -> "spotify:track:<id>"
    return id.startsWith("/com/spotify/") ? "spotify:" + id.slice(13).replace(/\//g, ":") : "";
  }

  property string token: ""
  // when the token runs out (ms since the epoch)
  property real expires: 0
  // calls waiting for a token
  property var waiting: []
  // when the queue was last fetched (ms since the epoch)
  property real fetched: 0
  // the queue may be behind: a track changed while nobody was looking
  property bool stale: true

  readonly property bool usable: status === "ready" || status === "loading" || status === "error"

  function look() {
    if (status === "off" || status === "linking")
      return;
    if (stale || Date.now() - fetched > 30000)
      fetchQueue();
  }

  function link() {
    if (linker.running)
      return;
    status = "linking";
    linker.running = true;
  }

  function isLiked(uri: string): var {
    return uri in liked ? liked[uri] : null;
  }

  function toggleLike(uri: string) {
    const was = isLiked(uri);
    if (was === null || status !== "ready")
      return;
    // shown at once; put back if Spotify refuses
    setLiked([uri], [!was]);
    call(was ? "DELETE" : "PUT", `/me/library?uris=${encodeURIComponent(uri)}`, () => {}, () => setLiked([uri], [was]));
  }

  function setLiked(uris: var, states: var) {
    const next = Object.assign({}, liked);
    uris.forEach((u, i) => next[u] = states[i]);
    liked = next;
  }

  function fetchQueue() {
    if (!queueKnown)
      status = "loading";
    stale = false;
    fetched = Date.now();
    call("GET", "/me/player/queue", res => {
      queue = (res?.queue ?? []).filter(t => t?.uri).map(t => ({
            uri: t.uri,
            title: t.name ?? "",
            // a track's artists; an episode's show
            artist: t.artists ? t.artists.map(a => a.name).join(", ") : (t.show?.name ?? ""),
            length: Math.round((t.duration_ms ?? 0) / 1000),
            // the smallest cover: the images come largest first
            art: (t.album?.images ?? t.images ?? []).slice(-1)[0]?.url ?? ""
          }));
      queueKnown = true;
      status = "ready";
      fetchLiked();
    });
  }

  // the playing track and the first of the queue, at most 40 to a call
  function fetchLiked() {
    const uris = [current, ...queue.slice(0, 20).map(t => t.uri)].filter((u, i, all) => u && all.indexOf(u) === i && !(u in liked)).slice(0, 40);
    if (uris.length === 0)
      return;
    call("GET", `/me/library/contains?uris=${encodeURIComponent(uris.join(","))}`, res => {
      if (Array.isArray(res))
        setLiked(uris, res.map(Boolean));
    });
  }

  // an API call with a valid token; `failed` runs as well as the status
  // turning to "error" when it does not go through
  function call(method: string, path: string, done: var, failed: var) {
    withToken(() => send(method, path, done, failed, true));
  }

  function send(method: string, path: string, done: var, failed: var, again: bool) {
    const xhr = new XMLHttpRequest();
    xhr.open(method, "https://api.spotify.com/v1" + path);
    xhr.setRequestHeader("Authorization", `Bearer ${token}`);
    xhr.onreadystatechange = () => {
      if (xhr.readyState !== XMLHttpRequest.DONE)
        return;
      if (xhr.status === 401 && again) {
        // the token went early: one more try with a new one
        token = "";
        withToken(() => send(method, path, done, failed, false));
        return;
      }
      if (xhr.status < 200 || xhr.status >= 300) {
        console.warn(`spotify: ${method} ${path.split("?")[0]} answered ${xhr.status || "nothing"}`);
        status = "error";
        failed?.();
        return;
      }
      let res = null;
      try {
        res = xhr.responseText ? JSON.parse(xhr.responseText) : null;
      } catch (e) {}
      if (status === "error")
        status = "ready";
      done(res);
    };
    xhr.send();
  }

  function withToken(then: var) {
    if (token && Date.now() < expires - 60000) {
      then();
      return;
    }
    waiting = [...waiting, then];
    if (!tokens.running)
      tokens.running = true;
  }

  function forget() {
    token = "";
    waiting = [];
    queue = [];
    queueKnown = false;
    liked = ({});
  }

  // the next track was the first in the queue: it moves up here at once,
  // and Spotify is asked again once it has caught up
  Connections {
    target: Media.player

    function onPostTrackChanged() {
      if (root.queue.length > 0 && root.queue[0].uri === root.current)
        root.queue = root.queue.slice(1);
      root.stale = true;
      if (root.watched && root.usable)
        catchUp.restart();
      else if (root.usable)
        root.fetchLiked();
    }
  }

  onWatchedChanged: {
    if (watched)
      look();
  }

  Timer {
    id: catchUp
    interval: 1500
    onTriggered: root.fetchQueue()
  }

  Process {
    id: tokens
    // through sh, so a missing bar-spotify (not deployed yet) still exits,
    // with 127
    command: ["sh", "-c", "exec bar-spotify token"]
    stdout: StdioCollector {
      id: tokenOut
    }
    onExited: code => {
      const then = root.waiting;
      root.waiting = [];
      if (code === 0) {
        try {
          const got = JSON.parse(tokenOut.text);
          root.token = got.access_token;
          root.expires = Date.now() + got.expires_in * 1000;
          then.forEach(f => f());
          return;
        } catch (e) {}
      }
      if (code === 3) {
        root.status = "off";
      } else if (code === 4) {
        root.forget();
        root.status = "unlinked";
      } else {
        root.status = "error";
      }
    }
  }

  Process {
    id: linker
    command: ["sh", "-c", "exec bar-spotify link"]
    onExited: code => {
      if (code === 0) {
        root.forget();
        root.fetchQueue();
      } else {
        root.status = code === 3 ? "off" : "unlinked";
      }
    }
  }
}
