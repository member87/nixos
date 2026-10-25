import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.services

// Shown only while something is watching or listening: the screen in red,
// the microphone in orange (struck through when muted). Hover names the
// apps; clicking the microphone mutes or unmutes it.
RowLayout {
  id: root

  visible: Privacy.screenShared || Privacy.micInUse
  spacing: 2

  Clickable {
    id: screen

    visible: Privacy.screenShared
    padX: 6
    padY: 2
    radius: 10
    hoverColor: Qt.rgba(251 / 255, 73 / 255, 52 / 255, 0.15)
    cursorShape: Qt.ArrowCursor

    Glyph {
      text: "\u{F1483}"
      color: Theme.critical
    }

    Tooltip {
      target: screen
      hovered: screen.containsMouse
      text: {
        const what = Privacy.castKind === "window" ? "A window is" : Privacy.castTarget ? `Screen ${Privacy.castTarget} is` : "Your screen is";
        const apps = Privacy.castApps.length > 0 ? ` with ${Privacy.castApps.join(", ")}` : "";
        return `${what} being shared${apps}`;
      }
    }
  }

  Clickable {
    id: mic

    visible: Privacy.micInUse
    padX: 6
    padY: 2
    radius: 10
    hoverColor: Qt.rgba(254 / 255, 128 / 255, 25 / 255, 0.15)
    onClicked: Audio.toggleMute(Audio.source)

    Glyph {
      text: Icons.microphone(Audio.inputMuted)
      color: Theme.orange
    }

    Tooltip {
      target: mic
      hovered: mic.containsMouse
      text: `Microphone ${Audio.inputMuted ? "muted, still open" : "in use"} by ${Privacy.micApps.join(", ")}. Click to ${Audio.inputMuted ? "unmute" : "mute"}`
    }
  }
}
