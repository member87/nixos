# Product

<!-- impeccable:product-schema 1 -->

## Platform

linux-desktop (Wayland layer-shell on Hyprland; Qt Quick through Quickshell 0.3)

## Users

One person, Jack, on his own machines: odin (a 3440×1440 ultrawide desktop with no battery or backlight) and thor (a laptop with a fingerprint reader). It is his daily driver for development work, so the shell sits at the edge of his vision for hours while a terminal or editor has the focus.

## Product Purpose

A personal desktop shell that replaces ags, swaync, swayosd, lxqt-policykit-agent, hyprland-share-picker, hyprpaper and a stock greeter with one Quickshell config. Success means everything the session needs (workspaces, status, sound, network, Bluetooth, notifications, media, the wallpaper, the lock screen, login, admin prompts, screen sharing) is one glance or one click away, and none of it pulls attention while he works.

## Positioning

One coherent world drawn from his own wallpaper: gruvbox over five coloured stripes with Tux in the middle. The bar's popouts grow out of the bar as a single surface, the desktop widgets rise out of the wallpaper's stripes, and the lock screen turns those stripes into its status line.

## Operating Context

- `shell.qml` runs as the `quickshell` systemd user service (the wallpaper, one bar and one desktop per screen; popups, OSD and polkit on the focused monitor). The wallpaper image is fetched in `default.nix` and handed over in the service's `QS_WALLPAPER`; without it (`qs -p`) the screens show the ground colour. `lock.qml` runs under hypridle's `lock_cmd`, `greeter.qml` under greetd inside a bare Hyprland, and `sharepicker.qml` under xdg-desktop-portal-hyprland (its `custom_picker_binary`) when an app asks to share the screen.
- It is opened by pointer and by keybind over IPC (`qs -c bar ipc call menu toggle <page>` with a system menu tab (power, network, sound, bluetooth, nixos), main for the default tab (Sound), or notifications; `ipc call osd brightness`, `ipc call power set <profile>` / `ipc call power cycle`).
- Media widgets show Spotify only. Lyrics come from LRCLIB and the visualizer reads PipeWire peaks. The bar's music drawer adds Up next and likes from the Spotify Web API through `bar-spotify` (a PKCE sign-in in the browser; its refresh token stays in `$XDG_STATE_HOME/quickshell/spotify.json`). It needs a Development Mode app, whose owner is on Premium; its client ID is the agenix secret `secrets/spotify_client_id.age`, decrypted to `/run/agenix` at boot, never in the repo or the store in plain text.
- Casting goes through `bar-cast` (Chromecast and AirPlay).
- The system menu's Network tab runs Tailscale through its CLI (`tailscale status --json` every 5s, `tailscale debug prefs` while the tab is open; `up`, `down`, `set`, `logout`), which needs no root because the user is tailscaled's operator (`hosts/common/core/tailscale.nix`). Signing in asks tailscaled for an interactive login over its LocalAPI and opens the page it returns in the browser. The tab switches it, picks the exit node and the run-time settings (local network access, subnet routes, tailnet DNS, incoming connections), lists the tailnet's devices (a click copies the address) and logs out; an exit node in use lights the bar's VPN icon, red while that node is offline. ProtonVPN is shown there too, status only.
- The system menu's NixOS tab compares the running generation (`nixos-version --json`) with `main` of github:member87/nixos, which the nightly builder pushes and the 05:00 upgrade installs. It checks as the menu opens, GitHub at most every 10 minutes, unauthenticated, and a waiting update puts a dot on the tab's rail icon. The tab shows the same comparison in detail, the running and next-boot kernel, what the generation brought into the store against the previous one (by cache signature, built here, or already present; `nix path-info`), and the nixos-upgrade service's last run (result, nix's reported download, from the journal) and next run.

## Capabilities and Constraints

- Wayland layer surfaces under Hyprland: popouts are xdg popups or layer surfaces with a Hyprland focus grab, and input masks limit where clicks land.
- Previews: `QS_LOCK_PREVIEW=1` for the lock, and the greeter falls back to preview without a greetd socket.
- It is packaged by the Home Manager module in `default.nix`. Config files are symlinked from the Nix store, so live testing runs `qs -p` against the repo.
- Hosts differ: odin has no battery, brightness or power-profiles-daemon, and thor has a fingerprint reader and power profiles. The code must handle both when either is absent.

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
