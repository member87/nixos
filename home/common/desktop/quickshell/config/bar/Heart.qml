import QtQuick
import qs.common
import qs.components
import qs.services

// like / unlike a Spotify track: red and filled when liked, an outline when
// not. Hidden while it is not known (not linked, not asked yet); greyed out
// while Spotify cannot be reached, since a change could not be saved.
Clickable {
  id: root

  required property string uri
  property int size: 16
  readonly property var liked: Spotify.isLiked(uri)

  visible: uri !== "" && liked !== null && Spotify.usable
  enabled: Spotify.status === "ready"
  implicitWidth: size + 12
  implicitHeight: size + 12
  radius: Theme.radiusControl
  onClicked: {
    // the heart fills with a small beat
    if (!liked)
      beat.restart();
    Spotify.toggleLike(uri);
  }

  Glyph {
    id: glyph
    text: root.liked ? Icons.heart : Icons.heartOutline
    color: root.liked ? Theme.critical : Theme.fg
    font.pixelSize: root.size
    renderType: Text.QtRendering
  }

  NumberAnimation {
    id: beat
    target: glyph
    property: "scale"
    from: 0.7
    to: 1
    duration: Theme.base
    easing.type: Theme.easeOut
  }
}
