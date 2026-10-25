pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
  id: root

  readonly property PwNode sink: Pipewire.defaultAudioSink
  readonly property PwNode source: Pipewire.defaultAudioSource

  // hardware devices (and virtual ones like loopbacks), not programs; by
  // name so the chooser does not reshuffle when PipeWire re-announces nodes.
  // bar-cast's "Cast: …" sink is listed under its cast device instead.
  readonly property list<PwNode> sinks: Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream && n.name !== "bar_cast").sort((a, b) => deviceName(a).localeCompare(deviceName(b)))
  readonly property list<PwNode> sources: Pipewire.nodes.values.filter(n => n.audio && !n.isSink && !n.isStream).sort((a, b) => deviceName(a).localeCompare(deviceName(b)))
  // programs playing audio (Stream/Output/Audio)
  readonly property list<PwNode> streams: Pipewire.nodes.values.filter(n => n.audio && n.isSink && n.isStream)

  readonly property real volume: sink?.audio?.volume ?? 0
  readonly property bool muted: sink?.audio?.muted ?? true
  readonly property real inputVolume: source?.audio?.volume ?? 0
  readonly property bool inputMuted: source?.audio?.muted ?? true

  function setVolume(node: PwNode, value: real) {
    if (!node?.audio)
      return;
    node.audio.muted = false;
    node.audio.volume = Math.max(0, Math.min(1, value));
  }

  function toggleMute(node: PwNode) {
    if (node?.audio)
      node.audio.muted = !node.audio.muted;
  }

  function setDefaultSink(node: PwNode) {
    Pipewire.preferredDefaultAudioSink = node;
  }

  function setDefaultSource(node: PwNode) {
    Pipewire.preferredDefaultAudioSource = node;
  }

  function deviceName(node: PwNode): string {
    if (!node)
      return "No device";
    return node.description || node.nickname || node.name;
  }

  // streams name themselves after their audio library ("WEBRTC VoiceEngine"
  // is Discord); the process binary, minus nix's ".foo-wrapped", finds the
  // app's desktop entry and with it the real name and icon
  function appEntry(node: PwNode): var {
    // desktop entries are scanned asynchronously at startup; reading the
    // list makes bindings that call this re-run once it is populated
    if (DesktopEntries.applications.values.length === 0)
      return null;
    const p = node.properties;
    const binary = (p["application.process.binary"] ?? "").replace(/^\./, "").replace(/-wrapped$/, "");
    return (binary && DesktopEntries.heuristicLookup(binary)) || (p["application.name"] && DesktopEntries.heuristicLookup(p["application.name"])) || null;
  }

  function appName(node: PwNode): string {
    return appEntry(node)?.name || node.properties["application.name"] || node.description || node.name || "Unknown";
  }

  function appIcon(node: PwNode): string {
    const name = node.properties["application.icon-name"] || appEntry(node)?.icon || "";
    return name ? Quickshell.iconPath(name, true) : "";
  }

  // volume, mute and properties of a node are only valid while it is bound
  PwObjectTracker {
    objects: [root.sink, root.source, ...root.streams]
  }
}
