import { createBinding, createComputed, With } from "ags"
import { Gtk } from "ags/gtk4"
import Pango from "gi://Pango?version=1.0"
import Mpris from "gi://AstalMpris"
import Network from "gi://AstalNetwork"
import CoverArt from "./CoverArt"
import {
  batteryPercent,
  batteryCharging,
  batteryPresent,
  batteryStateText,
  network,
  wifiEnabled,
  wifiSsid,
  wifiInternet,
  primaryConnection,
  wiredInternet,
  bluetooth,
  bluetoothPowered,
  brightness,
  wp,
  speakerVolume,
  speakerMuted,
  screenBrightness,
} from "../lib/system"
import { vpn } from "../lib/vpn"
import { time, fullDate, day } from "../lib/time"
import {
  batteryIcon,
  volumeIcon,
  ETHERNET_ICON,
  WIFI_DISCONNECTED_ICON,
  BRIGHTNESS_ICON,
  BLUETOOTH_ON_ICON,
  BLUETOOTH_OFF_ICON,
  VPN_LOCKED_ICON,
  VPN_UNLOCKED_ICON,
  MEDIA_PREV_ICON,
  MEDIA_PLAY_ICON,
  MEDIA_PAUSE_ICON,
  MEDIA_NEXT_ICON,
} from "../lib/icons"

const { VERTICAL, HORIZONTAL } = Gtk.Orientation
const { START, CENTER, END } = Gtk.Align
const mpris = Mpris.get_default()

function isConnected(): boolean {
  if (primaryConnection() === Network.Primary.WIRED) return wiredInternet() === Network.Internet.CONNECTED
  if (primaryConnection() === Network.Primary.WIFI) return wifiInternet() === Network.Internet.CONNECTED
  return false
}

function VolumeControl() {
  const icon = createComputed(() => volumeIcon(Math.round(speakerVolume() * 100), speakerMuted()))

  return (
    <box class="slider-module system-menu-section" spacing={8} hexpand>
      <label class="icon popup" label={icon} />
      <slider
        hexpand
        valign={CENTER}
        min={0}
        max={1}
        value={speakerVolume}
        // gnim connects signals with plain positional args: (self, scroll, value).
        // Return nothing - a truthy return marks change-value "handled" and
        // skips GtkRange's default handler that moves the adjustment.
        onChangeValue={(_self, _scroll, value) => {
          wp.audio.defaultSpeaker.volume = value
        }}
      />
    </box>
  )
}

function BrightnessControl() {
  if (!screenBrightness) return null

  return (
    <box class="slider-module system-menu-section" spacing={8} hexpand>
      <label class="icon popup" label={BRIGHTNESS_ICON} />
      <slider
        hexpand
        valign={CENTER}
        min={0}
        max={1}
        value={screenBrightness}
        onChangeValue={(_self, _scroll, value) => {
          brightness.screen!.brightness = value
        }}
      />
    </box>
  )
}

function BatteryStatus() {
  const icon = createComputed(() => batteryIcon(batteryPercent(), batteryCharging()))
  // one line: "85% (Charging)" - the old stacked (state) label wrapped to
  // multiple lines in its narrow column and inflated the whole row height
  const text = createComputed(() => {
    const state = batteryStateText()
    const pct = `${batteryPercent()}%`
    return state === "Charging" || state === "Full" ? `${pct} (${state})` : pct
  })

  return (
    <With value={batteryPresent}>
      {(present) =>
        present && (
          <box class="slider-module system-menu-section" spacing={8} hexpand>
            <label class="icon popup" label={icon} />
            <progressbar hexpand valign={CENTER} fraction={batteryPercent((p) => p / 100)} />
            <label class="battery-label" label={text} />
          </box>
        )
      }
    </With>
  )
}

function QuickToggles() {
  const connected = createComputed(isConnected)

  const wifiClasses = createComputed(() => {
    if (connected()) return ["menu-grid-item", "active-connected"]
    return wifiEnabled() ? ["menu-grid-item", "active"] : ["menu-grid-item"]
  })
  const wifiGlyph = createComputed(() => {
    if (primaryConnection() === Network.Primary.WIRED && connected()) return ETHERNET_ICON
    return wifiEnabled() ? "󰤨" : WIFI_DISCONNECTED_ICON
  })
  const wifiLabel = createComputed(() => {
    if (primaryConnection() === Network.Primary.WIRED && connected()) return "Ethernet"
    return wifiEnabled() ? wifiSsid() : "WiFi"
  })

  const bluetoothClasses = bluetoothPowered((on) =>
    on ? ["menu-grid-item", "active"] : ["menu-grid-item"],
  )
  const vpnClasses = vpn((v) => (v.connected ? ["menu-grid-item", "active-connected"] : ["menu-grid-item"]))

  return (
    <box class="system-menu-section grid-box" orientation={VERTICAL} spacing={10}>
      <box orientation={HORIZONTAL} spacing={10}>
        <button
          cssClasses={wifiClasses}
          onClicked={() => {
            if (network.wifi) network.wifi.set_enabled(!network.wifi.enabled)
          }}
        >
          <box orientation={VERTICAL} spacing={2}>
            <label class="grid-item-icon" halign={CENTER} label={wifiGlyph} />
            <label class="grid-item-label" label={wifiLabel} />
          </box>
        </button>

        <button cssClasses={bluetoothClasses} onClicked={() => bluetooth.toggle()}>
          <box orientation={VERTICAL} spacing={2}>
            <label
              class="grid-item-icon"
              label={bluetoothPowered((on) => (on ? BLUETOOTH_ON_ICON : BLUETOOTH_OFF_ICON))}
            />
            <label class="grid-item-label" label="Bluetooth" />
          </box>
        </button>

        <box cssClasses={vpnClasses} orientation={VERTICAL} spacing={2}>
          <label
            class="grid-item-icon"
            label={vpn((v) => (v.connected ? VPN_LOCKED_ICON : VPN_UNLOCKED_ICON))}
          />
          <label class="grid-item-label" label={vpn((v) => (v.connected ? v.ip : "VPN"))} />
        </box>
      </box>
    </box>
  )
}

function MediaPanel() {
  const player = createBinding(mpris, "players")((players) => players[0] ?? null)

  return (
    <With value={player}>
      {(p) =>
        p && (
          <overlay class="media-player">
            {/* full-bleed album art background with a scrim for legibility;
                info and controls are overlaid on top of it. CoverArt reloads
                in place - no <With> (it would re-append children at the end) */}
            <CoverArt path={createBinding(p, "coverArt")} radius={10} scrim={0.45} width={1} height={1} hexpand vexpand />
            <box
              $type="overlay"
              class="media-overlay"
              orientation={VERTICAL}
              valign={CENTER}
              spacing={4}
              hexpand
            >
              <label
                class="media-title"
                halign={START}
                maxWidthChars={25}
                ellipsize={Pango.EllipsizeMode.END}
                label={createBinding(p, "title")((t) => t ?? "Unknown Track")}
              />
              <label
                class="media-artist"
                halign={START}
                maxWidthChars={20}
                ellipsize={Pango.EllipsizeMode.END}
                label={createBinding(p, "artist")((a) => a ?? "Unknown Artist")}
              />
              <box class="media-controls" spacing={20} halign={START}>
                <button class="media-button" onClicked={() => p.previous()} label={MEDIA_PREV_ICON} />
                <button
                  class="media-button"
                  onClicked={() => p.play_pause()}
                  label={createBinding(p, "playbackStatus")((s) =>
                    s === Mpris.PlaybackStatus.PLAYING ? MEDIA_PAUSE_ICON : MEDIA_PLAY_ICON,
                  )}
                />
                <button class="media-button" onClicked={() => p.next()} label={MEDIA_NEXT_ICON} />
              </box>
            </box>
          </overlay>
        )
      }
    </With>
  )
}

export default function SystemMenu() {
  return (
    <box class="system-menu-box" orientation={VERTICAL} spacing={10}>
      <box class="time-date" spacing={0}>
        <box class="time-container" halign={START}>
          <label class="time" label={time} />
        </box>
        <box class="date-container" orientation={VERTICAL} halign={START}>
          <label class="date" label={fullDate} />
          <label class="day" label={day} />
        </box>
      </box>

      <VolumeControl />
      <BrightnessControl />
      <BatteryStatus />
      <QuickToggles />
      <MediaPanel />
    </box>
  )
}
