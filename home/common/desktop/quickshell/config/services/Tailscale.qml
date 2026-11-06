pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// tailscaled through its CLI. `tailscale status --json` (every 5s) gives the
// state, this device, the tailnet's devices and the exit node in use, which
// the bar shows; `tailscale debug prefs` the settings the network tab
// switches, read only while the tab is open (`detailed`). Changes go through
// `tailscale up / down / set / logout`, one at a time; they need no root,
// as this user is tailscaled's operator (hosts/common/core/tailscale.nix).
// Signing in asks tailscaled for an interactive login over its LocalAPI
// (what the official GUIs do): `tailscale login` would demand every
// non-default flag again, the login server included.
Singleton {
  id: root

  // the network tab is open: read the settings too
  property bool detailed: false

  // "" while tailscaled cannot be reached, otherwise its backend state:
  // NoState, NeedsLogin, NeedsMachineAuth, Stopped, Starting or Running
  property string backend: ""
  readonly property bool running: backend === "Running"
  // wanted up: connected, connecting, or waiting for the admin's approval
  readonly property bool on: running || backend === "Starting" || backend === "NeedsMachineAuth"
  // the browser page that finishes a sign-in, once tailscaled has one
  property string authUrl: ""

  property string tailnet: ""
  property string dnsName: "" // "thor.tailnet.jackhumes.com"
  property string ipv4: ""
  property string ipv6: ""
  property string account: ""
  // tailscaled's own warnings ("can't reach the configured DNS servers")
  property var health: []
  // {id, name, os, ipv4, online, lastSeen (ms; 0 while online), exitNodeOption}
  property var peers: []
  // the peer traffic leaves through, or null; while it is offline, so is
  // the internet
  property var exitNode: null
  readonly property var exitNodes: peers.filter(p => p.exitNodeOption)

  // the settings (prefs)
  property bool acceptRoutes: false
  property bool acceptDns: false
  property bool shieldsUp: false
  property bool allowLan: false

  // what the running command is doing ("Connecting…"), and the last one's
  // complaint
  property string doing: ""
  property string error: ""
  readonly property bool busy: doing !== ""
  property var queue: []
  // the running command was stopped for taking too long
  property bool timedOut: false
  // open the sign-in page as soon as tailscaled hands it over
  property bool signingIn: false

  function refresh() {
    status.running = true;
    if (detailed)
      prefs.running = true;
  }

  function toggle() {
    if (on)
      run("Disconnecting…", ["tailscale", "down"]);
    else if (backend === "NeedsLogin")
      signIn();
    else
      // bare: brings it up without touching any setting
      run("Connecting…", ["tailscale", "up"]);
  }

  function signIn() {
    if (authUrl !== "") {
      Qt.openUrlExternally(authUrl);
      return;
    }
    signingIn = true;
    run("Signing in…", ["tailscale", "debug", "localapi", "POST", "login-interactive"]);
  }

  function logOut() {
    run("Logging out…", ["tailscale", "logout"]);
  }

  // a peer, or null to send traffic out directly again
  function useExitNode(peer: var) {
    run("Switching exit node…", ["tailscale", "set", `--exit-node=${peer?.ipv4 ?? ""}`]);
  }

  // flag: a `tailscale set` flag ("accept-routes")
  function setPref(flag: string, value: bool) {
    run("Saving…", ["tailscale", "set", `--${flag}=${value}`]);
  }

  function copy(text: string) {
    Quickshell.execDetached(["wl-copy", text]);
  }

  function run(label: string, command: var) {
    queue = queue.concat([
      {
        label,
        command
      }
    ]);
    if (!action.running)
      next();
  }

  function next() {
    const job = queue[0];
    if (!job) {
      doing = "";
      return;
    }
    queue = queue.slice(1);
    doing = job.label;
    timedOut = false;
    action.command = job.command;
    action.running = true;
  }

  // "Access denied: prefs write access denied" rather than its whole
  // advice; the LocalAPI call prefixes its own lines with "#"
  function complaint(text: string): string {
    return text.split("\n").map(l => l.trim()).find(l => l !== "" && !l.startsWith("#")) ?? "";
  }

  function ms(iso: string): real {
    const t = Date.parse(iso ?? "");
    // Go's zero time, 0001-01-01, for devices online now or never seen
    return isNaN(t) || t < 0 ? 0 : t;
  }

  // a poll that changed nothing keeps the old lists, so the rows built
  // from them (hover, focus, "Copied") survive it
  function same(a: var, b: var): bool {
    return JSON.stringify(a) === JSON.stringify(b);
  }

  function parse(s: var) {
    backend = s.BackendState ?? "";
    authUrl = s.AuthURL ?? "";
    tailnet = s.CurrentTailnet?.Name ?? "";
    const self = s.Self ?? {};
    dnsName = (self.DNSName ?? "").replace(/\.$/, "");
    const ips = self.TailscaleIPs ?? [];
    ipv4 = ips.find(ip => !ip.includes(":")) ?? "";
    ipv6 = ips.find(ip => ip.includes(":")) ?? "";
    account = s.User?.[self.UserID]?.LoginName ?? "";
    const warnings = s.Health ?? [];
    if (!same(warnings, health))
      health = warnings;
    const list = Object.values(s.Peer ?? {}).map(p => ({
          id: p.ID,
          // the MagicDNS label: phones call themselves "localhost"
          name: (p.DNSName ?? "").split(".")[0] || p.HostName,
          os: p.OS ?? "",
          ipv4: (p.TailscaleIPs ?? []).find(ip => !ip.includes(":")) ?? "",
          online: p.Online ?? false,
          lastSeen: p.Online ? 0 : ms(p.LastSeen),
          exitNodeOption: p.ExitNodeOption ?? false
        })).sort((a, b) => b.online - a.online || (b.online ? 0 : b.lastSeen - a.lastSeen) || a.name.localeCompare(b.name));
    if (!same(list, peers))
      peers = list;
    // a node not in the peer list (shared out of another tailnet) goes by
    // its address
    const exit = s.ExitNodeStatus;
    const exitIp = (exit?.TailscaleIPs ?? []).map(ip => ip.replace(/\/\d+$/, "")).find(ip => !ip.includes(":")) ?? "";
    const via = exit ? (peers.find(p => p.id === exit.ID) ?? {
        id: exit.ID,
        name: exitIp,
        os: "",
        ipv4: exitIp,
        online: exit.Online ?? false,
        lastSeen: 0,
        exitNodeOption: true
      }) : null;
    if (!same(via, exitNode))
      exitNode = via;
    if (signingIn && authUrl !== "") {
      signingIn = false;
      Qt.openUrlExternally(authUrl);
    }
  }

  onDetailedChanged: {
    if (detailed)
      refresh();
  }

  Process {
    id: status
    command: ["tailscale", "status", "--json"]
    stdout: StdioCollector {
      id: statusOut
    }
    onExited: code => {
      if (code !== 0) {
        root.backend = "";
        return;
      }
      try {
        root.parse(JSON.parse(statusOut.text));
      } catch (e) {
        console.warn(`tailscale: unreadable status: ${e}`);
        root.backend = "";
      }
    }
  }

  Process {
    id: prefs
    command: ["tailscale", "debug", "prefs"]
    stdout: StdioCollector {
      id: prefsOut
    }
    onExited: code => {
      if (code !== 0)
        return;
      try {
        const p = JSON.parse(prefsOut.text);
        root.acceptRoutes = p.RouteAll ?? false;
        root.acceptDns = p.CorpDNS ?? false;
        root.shieldsUp = p.ShieldsUp ?? false;
        root.allowLan = p.ExitNodeAllowLANAccess ?? false;
      } catch (e) {
        console.warn(`tailscale: unreadable prefs: ${e}`);
      }
    }
  }

  Process {
    id: action
    stdout: StdioCollector {
      id: actionOut
    }
    stderr: StdioCollector {
      id: actionErr
    }
    onExited: code => {
      if (code === 0 || root.timedOut) {
        root.error = "";
      } else {
        root.error = root.complaint(actionErr.text) || root.complaint(actionOut.text) || `tailscale exited with ${code}`;
        root.signingIn = false;
      }
      root.refresh();
      root.next();
    }
  }

  // `tailscale up` waits for the connection; a tailnet that never answers
  // must not hold up the queue. Stopping it leaves tailscaled trying.
  Timer {
    interval: 20000
    running: action.running
    onTriggered: {
      root.timedOut = true;
      action.running = false;
    }
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }
}
