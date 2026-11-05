import QtQuick
import Quickshell.Io

// What the running generation brought and how the nightly upgrade went,
// read once as the NixOS page opens. Invisible so it takes no slot in a
// layout.
//
// - The generation: the system profile's links give its number and when it
//   was switched to. The paths in its closure that the previous one's lacks
//   are what it brought; nix path-info tells where each came from: signed by
//   a cache's key, or built here (ultimate, or unsigned: sources added
//   during evaluation). Ones registered before the previous generation was
//   switched to were already in the store (a rollback, an earlier build).
// - The kernel booted against the one the generation boots next.
// - The nixos-upgrade service (hosts/common/core/nix-cache.nix): its last
//   run from the journal, which keeps it across reboots, with the download
//   nix reported then, and the timer's next run.
Item {
  id: root

  visible: false

  readonly property string profiles: "/nix/var/nix/profiles"

  property bool loaded: false

  // the generation; number 0 until known, previous 0 when none is kept
  property string path: ""
  readonly property int number: byPath[path] ?? 0
  readonly property int previous: {
    const below = Object.keys(links).map(Number).filter(n => n < number);
    return number > 0 && below.length > 0 ? Math.max(...below) : 0;
  }
  readonly property real switchedAt: links[number]?.time ?? 0 // ms
  // where its new paths came from, the largest first, then built here and
  // already here: [{ key, label, paths, bytes }]; key "built" / "kept" for
  // the last two, a cache's key name otherwise
  property var sources: []
  readonly property real newBytes: sources.reduce((n, s) => n + s.bytes, 0)
  readonly property int newPaths: sources.reduce((n, s) => n + s.paths, 0)
  // the largest paths built here, by name
  property var builtLargest: []

  // kernel versions: running, and the one the next boot runs
  property string kernel: ""
  property string nextKernel: ""

  // the nixos-upgrade timer; false on a host without system.autoUpgrade
  property bool upgrades: false
  property real nextRun: 0 // ms
  // its last run: state "", "running", "succeeded" or "failed"
  property string runState: ""
  property real runStart: 0
  property real runEnd: 0
  property real downloaded: 0 // bytes, as nix reported them
  property real unpacked: 0
  property int fetched: 0
  property string runConfig: "" // the system it built
  property string runError: ""
  // the generation that system is, 0 if it is gone or unknown
  readonly property int runNumber: byPath[runConfig] ?? 0
  readonly property bool fromUpgrade: path !== "" && runConfig === path

  // number -> { path, time } of every system-N-link, and path -> the
  // newest number linking it
  property var links: ({})
  property var byPath: ({})
  property bool listed: false
  property var previousSet: null
  property var currentList: null

  // signature key names as nix-cache.nix and nix.nix trust them
  function sourceLabel(key: string): string {
    if (key === "built")
      return "Built here";
    if (key === "kept")
      return "Already here";
    if (key === "jackhumes")
      return "Home cache";
    return key.replace(/-\d+$/, "");
  }

  // "/nix/store/<hash>-linux-zen-7.2.15/bzImage" -> "7.2.15"
  function kernelVersion(link: string): string {
    const name = link.split("/")[3]?.slice(33) ?? "";
    return name.match(/-(\d[\w.-]*)$/)?.[1] ?? name;
  }

  // nix's "787.5 MiB" -> bytes
  function parseSize(s: string): real {
    const m = s.match(/([\d.]+)\s*([KMGT]?)i?B/);
    if (!m)
      return 0;
    return Number(m[1]) * Math.pow(1024, " KMGT".indexOf(m[2] || " "));
  }

  Component.onCompleted: {
    profileLinks.running = true;
    systemLinks.running = true;
    timer.running = true;
    journal.running = true;
  }

  // the profile's links and /run/current-system both in: diff the closures
  function linksReady() {
    if (!root.listed || root.path === "")
      return;
    if (root.number === 0 || root.previous === 0) {
      root.loaded = true;
      return;
    }
    previousClosure.command = ["nix-store", "--query", "--requisites", root.links[root.previous].path];
    currentClosure.command = ["nix-store", "--query", "--requisites", root.path];
    previousClosure.running = true;
    currentClosure.running = true;
  }

  function closuresReady() {
    if (root.previousSet === null || root.currentList === null)
      return;
    const fresh = root.currentList.filter(p => !root.previousSet.has(p));
    if (fresh.length === 0) {
      root.loaded = true;
      return;
    }
    pathInfo.command = ["nix", "path-info", "--json", "--json-format", "1", ...fresh];
    pathInfo.running = true;
  }

  Process {
    id: profileLinks
    command: ["find", root.profiles, "-maxdepth", "1", "-name", "system-*-link", "-printf", "%f\t%l\t%T@\n"]
    stdout: StdioCollector {
      onStreamFinished: {
        const all = {};
        const byPath = {};
        for (const line of text.split("\n")) {
          const [name, target, mtime] = line.split("\t");
          const n = Number(name?.match(/^system-(\d+)-link$/)?.[1]);
          if (!n)
            continue;
          all[n] = {
            path: target,
            time: Number(mtime) * 1000
          };
          byPath[target] = Math.max(byPath[target] ?? 0, n);
        }
        root.links = all;
        root.byPath = byPath;
        root.listed = true;
        root.linksReady();
      }
    }
  }

  Process {
    id: systemLinks
    command: ["readlink", "/run/current-system", "/run/booted-system/kernel", "/run/current-system/kernel"]
    stdout: StdioCollector {
      onStreamFinished: {
        const [current, booted, next] = text.split("\n");
        root.kernel = booted ? root.kernelVersion(booted) : "";
        root.nextKernel = next ? root.kernelVersion(next) : "";
        root.path = current ?? "";
        root.linksReady();
      }
    }
  }

  Process {
    id: previousClosure
    stdout: StdioCollector {
      onStreamFinished: {
        root.previousSet = new Set(text.split("\n").filter(p => p !== ""));
        root.closuresReady();
      }
    }
  }

  Process {
    id: currentClosure
    stdout: StdioCollector {
      onStreamFinished: {
        root.currentList = text.split("\n").filter(p => p !== "");
        root.closuresReady();
      }
    }
  }

  Process {
    id: pathInfo
    stdout: StdioCollector {
      onStreamFinished: {
        let info;
        try {
          info = JSON.parse(text);
        } catch (e) {
          console.warn(`generation: unreadable nix path-info output`);
          root.loaded = true;
          return;
        }
        const since = root.links[root.previous].time / 1000;
        const by = {};
        const built = [];
        for (const [p, i] of Object.entries(info)) {
          if (!i)
            continue;
          let key;
          if (i.registrationTime < since)
            key = "kept";
          else if (i.ultimate || (i.signatures ?? []).length === 0)
            key = "built";
          else
            key = i.signatures[0].split(":")[0];
          by[key] = by[key] ?? {
            key,
            label: root.sourceLabel(key),
            paths: 0,
            bytes: 0
          };
          by[key].paths += 1;
          by[key].bytes += i.narSize;
          // what a builder ran for, not sources copied in
          if (key === "built" && i.ultimate)
            built.push({
              name: p.slice(44),
              bytes: i.narSize
            });
        }
        const last = k => k === "kept" ? 2 : k === "built" ? 1 : 0;
        root.sources = Object.values(by).sort((a, b) => last(a.key) - last(b.key) || b.bytes - a.bytes);
        root.builtLargest = built.sort((a, b) => b.bytes - a.bytes).slice(0, 3).map(b => b.name);
        root.loaded = true;
      }
    }
  }

  Process {
    id: timer
    command: ["systemctl", "show", "nixos-upgrade.timer", "--property=LoadState,NextElapseUSecRealtime", "--timestamp=unix"]
    stdout: StdioCollector {
      onStreamFinished: {
        const f = {};
        for (const line of text.split("\n")) {
          const i = line.indexOf("=");
          if (i > 0)
            f[line.slice(0, i)] = line.slice(i + 1);
        }
        root.upgrades = f.LoadState === "loaded";
        root.nextRun = Number(f.NextElapseUSecRealtime?.replace(/^@/, "") || 0) * 1000;
      }
    }
  }

  // systemd's own lines (pid 1) start and finish a run; the rest are
  // nixos-rebuild's and nix's. With --grep and --lines journalctl prints
  // the newest first.
  Process {
    id: journal
    command: ["journalctl", "--unit=nixos-upgrade.service", "--output=json", "--output-fields=MESSAGE,INVOCATION_ID,_SYSTEMD_INVOCATION_ID,JOB_TYPE,JOB_RESULT,_PID", "--grep=^(Starting|Finished|Failed|Done\\. |these |this |error: )", "--lines=400", "--no-pager"]
    stdout: StdioCollector {
      onStreamFinished: {
        const entries = [];
        for (const line of text.split("\n")) {
          try {
            if (line !== "")
              entries.push(JSON.parse(line));
          } catch (e) {}
        }
        entries.sort((a, b) => Number(a.__REALTIME_TIMESTAMP) - Number(b.__REALTIME_TIMESTAMP));
        const starts = entries.filter(e => e._PID === "1" && e.JOB_TYPE === "start" && !e.JOB_RESULT);
        const start = starts[starts.length - 1];
        if (!start)
          return;
        const id = start.INVOCATION_ID;
        root.runStart = Number(start.__REALTIME_TIMESTAMP) / 1000;
        root.runState = "running";
        let downloaded = 0, unpacked = 0, fetched = 0;
        for (const e of entries) {
          if ((e.INVOCATION_ID ?? e._SYSTEMD_INVOCATION_ID) !== id || typeof e.MESSAGE !== "string")
            continue;
          const msg = e.MESSAGE;
          if (e._PID === "1" && e.JOB_TYPE === "start" && e.JOB_RESULT) {
            root.runState = e.JOB_RESULT === "done" ? "succeeded" : "failed";
            root.runEnd = Number(e.__REALTIME_TIMESTAMP) / 1000;
          } else if (msg.startsWith("Done. The new configuration is ")) {
            root.runConfig = msg.slice(31).trim();
          } else if (msg.startsWith("error: ") && root.runError === "") {
            root.runError = msg.slice(7);
          } else {
            // "these 56 paths will be fetched (787.5 MiB download, 2.4 GiB unpacked):"
            const m = msg.match(/^(?:these (\d+) paths|this path) will be fetched \(([^,]+) download, ([^)]+) unpacked\)/);
            if (m) {
              fetched += m[1] ? Number(m[1]) : 1;
              downloaded += root.parseSize(m[2]);
              unpacked += root.parseSize(m[3]);
            }
          }
        }
        root.fetched = fetched;
        root.downloaded = downloaded;
        root.unpacked = unpacked;
      }
    }
  }
}
