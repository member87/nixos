pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Whether this machine runs the newest build of github:member87/nixos.
// The nightly builder pushes main only after building every host
// (hosts/common/core/nix-cache.nix), so main's head is what the 05:00
// upgrade installs. The running generation's commit comes from
// system.configurationRevision (lib/default.nix); nixpkgs is compared as
// well, which also covers a generation built before that was set.
//
// Checked when the system menu opens, GitHub at most every 10 minutes:
// unauthenticated, the API allows 60 requests an hour and a check uses two.
Singleton {
  id: root

  readonly property string repo: "member87/nixos"
  readonly property int minInterval: 10 * 60 * 1000

  // the running generation, from nixos-version --json
  property string version: "" // "26.11.20261103.1d06008"
  property string nixpkgsRev: ""
  property string revision: "" // the repo commit, "" if unrecorded
  property bool dirty: false // built from a checkout with changes

  // main's head
  property string latestVersion: ""
  property string latestRevision: ""
  property string latestNixpkgsRev: ""
  // commits on main the running one lacks, and its own commits main lacks;
  // behindBy is -1 when GitHub cannot compare them (no revision recorded, or
  // a commit never pushed: unpushed)
  property int behindBy: -1
  property int aheadBy: 0
  property bool unpushed: false

  property bool checking: false
  property string error: ""
  property real lastAttempt: 0

  readonly property bool known: latestRevision !== ""
  // whole days between the two nixpkgs snapshots
  readonly property int nixpkgsDays: known ? Math.max(0, Math.round((dayOf(latestVersion) - dayOf(version)) / 86400000)) : 0
  readonly property bool nixpkgsBehind: known && nixpkgsRev !== "" && latestNixpkgsRev !== nixpkgsRev
  readonly property bool outOfDate: known && (behindBy > 0 || (behindBy < 0 && nixpkgsBehind))
  readonly property bool localBuild: dirty || aheadBy > 0 || unpushed
  readonly property bool upToDate: known && version !== "" && !outOfDate && !localBuild

  // "20261103" in "26.11.20261103.1d06008", as a UTC timestamp
  function dayOf(v: string): real {
    const d = v.split(".")[2] ?? "";
    if (!/^\d{8}$/.test(d))
      return NaN;
    return Date.UTC(Number(d.slice(0, 4)), Number(d.slice(4, 6)) - 1, Number(d.slice(6, 8)));
  }

  // the running generation always; GitHub when the last try is old enough
  function refresh() {
    generation.running = true;
  }

  function get(url: string, accept: string, done: var) {
    const xhr = new XMLHttpRequest();
    xhr.open("GET", url);
    if (accept)
      xhr.setRequestHeader("Accept", accept);
    xhr.onreadystatechange = () => {
      if (xhr.readyState === XMLHttpRequest.DONE)
        done(xhr.status, xhr.responseText);
    };
    xhr.send();
  }

  // why: a message of its own, for an answer that came but made no sense
  function fail(status, why) {
    if (why)
      error = why;
    else if (status === 0)
      error = "Couldn't reach GitHub";
    else if (status === 403 || status === 429)
      error = "GitHub rate limit, try later";
    else
      error = `GitHub answered ${status}`;
    console.warn(`updates: ${error}`);
    checking = false;
  }

  function check() {
    if (checking || Date.now() - lastAttempt < minInterval)
      return;
    checking = true;
    lastAttempt = Date.now();
    get(`https://api.github.com/repos/${repo}/commits/main`, "application/vnd.github.sha", (status, text) => {
      if (status !== 200)
        return fail(status);
      const sha = text.trim();
      get(`https://raw.githubusercontent.com/${repo}/${sha}/flake.lock`, "", (status, text) => {
        if (status !== 200)
          return fail(status);
        let locked;
        try {
          const lock = JSON.parse(text);
          locked = lock.nodes[lock.nodes[lock.root].inputs.nixpkgs].locked;
        } catch (e) {
          return fail(200, "Unreadable flake.lock on main");
        }
        // lib/.version: the top-level one is a symlink, which raw serves as its target's path
        get(`https://raw.githubusercontent.com/NixOS/nixpkgs/${locked.rev}/lib/.version`, "", (status, text) => {
          if (status !== 200)
            return fail(status);
          const date = new Date(locked.lastModified * 1000).toISOString().slice(0, 10).replace(/-/g, "");
          const latest = `${text.trim()}.${date}.${locked.rev.slice(0, 7)}`;
          compare(sha, () => {
            root.latestRevision = sha;
            root.latestNixpkgsRev = locked.rev;
            root.latestVersion = latest;
            root.error = "";
            root.checking = false;
          });
        });
      });
    });
  }

  // how far the running commit is from main's head
  function compare(sha: string, done: var) {
    unpushed = false;
    if (revision === "") {
      behindBy = -1;
      aheadBy = 0;
      return done();
    }
    if (revision === sha) {
      behindBy = 0;
      aheadBy = 0;
      return done();
    }
    get(`https://api.github.com/repos/${repo}/compare/${revision}...${sha}`, "application/vnd.github+json", (status, text) => {
      // 404: a local commit GitHub has never seen
      if (status === 200) {
        const c = JSON.parse(text);
        root.behindBy = c.ahead_by;
        root.aheadBy = c.behind_by;
      } else if (status === 404) {
        root.behindBy = -1;
        root.aheadBy = 0;
        root.unpushed = true;
      } else {
        return root.fail(status);
      }
      done();
    });
  }

  Process {
    id: generation
    command: ["nixos-version", "--json"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const v = JSON.parse(text);
          const rev = v.configurationRevision ?? "";
          // a new generation since the last check: compare it again now
          if (v.nixosVersion !== root.version || rev !== root.revision.concat(root.dirty ? "-dirty" : ""))
            root.lastAttempt = 0;
          root.version = v.nixosVersion ?? "";
          root.nixpkgsRev = v.nixpkgsRevision ?? "";
          root.dirty = rev.endsWith("-dirty");
          root.revision = rev.replace(/-dirty$/, "");
        } catch (e) {
          console.warn(`updates: unreadable nixos-version output: ${text}`);
        }
        root.check();
      }
    }
  }
}
