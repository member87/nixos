# Product

<!-- impeccable:product-schema 1 -->

## Platform

linux-desktop (Wayland layer-shell on Hyprland; Qt Quick through Quickshell 0.3)

## Users

One person, Jack, on his own machines: odin (a 3440×1440 ultrawide desktop with no battery or backlight) and thor (a laptop with a fingerprint reader). It is his daily driver for development work, so the shell sits at the edge of his vision for hours while a terminal or editor has the focus.

## Product Purpose

A personal desktop shell that replaces ags, swaync, swayosd, lxqt-policykit-agent and a stock greeter with one Quickshell config. Success means everything the session needs (workspaces, status, sound, network, Bluetooth, notifications, media, the lock screen, login, admin prompts) is one glance or one click away, and none of it pulls attention while he works.

## Positioning

One coherent world drawn from his own wallpaper: gruvbox over five coloured stripes with Tux in the middle. The bar's popouts grow out of the bar as a single surface, the desktop widgets rise out of the wallpaper's stripes, and the lock screen turns those stripes into its status line.

## Operating Context

- `shell.qml` runs as the `quickshell` systemd user service (one bar and one desktop per screen; popups, OSD and polkit on the focused monitor). `lock.qml` runs under hypridle's `lock_cmd`, and `greeter.qml` under greetd inside a bare Hyprland.
- It is opened by pointer and by keybind over IPC (`qs -c bar ipc call menu toggle <page>`, `ipc call osd brightness`).
- Media widgets show Spotify only. Lyrics come from LRCLIB and the visualizer reads PipeWire peaks.
- Casting goes through `bar-cast` (Chromecast and AirPlay).

## Capabilities and Constraints

- Wayland layer surfaces under Hyprland: popouts are xdg popups or layer surfaces with a Hyprland focus grab, and input masks limit where clicks land.
- Previews: `QS_LOCK_PREVIEW=1` for the lock, and the greeter falls back to preview without a greetd socket.
- It is packaged by the Home Manager module in `default.nix`. Config files are symlinked from the Nix store, so live testing runs `qs -p` against the repo.
- Hosts differ: odin has no battery or brightness and thor has a fingerprint reader. The code must handle both when either is absent.

## Brand Commitments

- The gruvbox dark palette, carried over from the ags bar's style.scss (see `config/common/Theme.qml`).
- FiraCode Nerd Font for text and icons, and the oomox-gruvbox-dark icon theme.
- The wallpaper's five stripes and Tux as the motif for the desktop, the lock and the greeter.
- Motion: quiet and quick in the bar and everything used while working; more expressive on the empty desktop and the lock and login screens.

## Evidence on Hand

The running config itself and its long design comments. There are no external users, metrics or testimonials, and none should be invented.

## Product Principles

1. The work has the focus. Anything visible while a window is open stays quiet, quick and still at rest.
2. One surface. Popouts, menus and the desktop extend the bar and the wallpaper; they are never separate floating chrome.
3. Show state, not chrome. Every indicator earns its place by reporting something true right now, and anything idle hides.
4. Keyboard and pointer are equals. Everything reachable by click is reachable by keybind or IPC, and focus is never stolen without reason.
5. Fail visibly and calmly. Missing hardware, failed lookups and refused locks degrade to a clear line of text, not a broken surface.
