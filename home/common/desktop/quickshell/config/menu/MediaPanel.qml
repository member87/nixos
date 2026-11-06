import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell.Widgets
import qs.services
import qs.common
import qs.components

// now playing: the cover, the track, its controls and its heart, on a card
// shaded from the cover's two main colours, bottom left to top right
Item {
  id: root

  readonly property var player: Media.player
  // the section fill until a cover with colours of its own has loaded
  property var tints: [Theme.sectionBg, Theme.sectionBg]

  // a cover colour as a dark, muted shade the text stays legible on
  function shade(bin: var, lightness: real): color {
    const c = Qt.rgba(bin.r / bin.weight, bin.g / bin.weight, bin.b / bin.weight, 1);
    return Qt.hsla(c.hslHue, Math.min(c.hslSaturation, 0.45), lightness, 1);
  }

  // the cover's two main colours: pixels are binned by hue, weighted by how
  // vivid they are, and the two heaviest bins that differ enough in hue are
  // averaged. A muted cover gives muted shades; a cover of one colour
  // shades from it to a darker step of it; a grey one keeps the section fill.
  function tintsOf(data: var): var {
    const bins = [];
    for (let i = 0; i < data.length; i += 4) {
      const c = Qt.rgba(data[i] / 255, data[i + 1] / 255, data[i + 2] / 255, 1);
      const weight = c.hsvSaturation * c.hsvValue;
      // near-greys have no hue worth taking
      if (data[i + 3] < 128 || weight < 0.03)
        continue;
      const bin = Math.floor(Math.max(0, c.hslHue) * 12) % 12;
      bins[bin] = bins[bin] ?? {
        hue: bin,
        weight: 0,
        r: 0,
        g: 0,
        b: 0
      };
      bins[bin].weight += weight;
      bins[bin].r += c.r * weight;
      bins[bin].g += c.g * weight;
      bins[bin].b += c.b * weight;
    }
    const ranked = bins.filter(b => b).sort((a, b) => b.weight - a.weight);
    const first = ranked[0];
    // a few tinted pixels in a grey cover are not its colour
    if (!first || first.weight < data.length / 4 * 0.005)
      return [Theme.sectionBg, Theme.sectionBg];
    // at least 60° round the wheel, and more than a fleck
    const apart = b => Math.min(Math.abs(b.hue - first.hue), 12 - Math.abs(b.hue - first.hue)) >= 2;
    const second = ranked.find(b => apart(b) && b.weight >= first.weight * 0.15);
    return [shade(first, 0.2), second ? shade(second, 0.2) : shade(first, 0.12)];
  }

  visible: player !== null
  Layout.fillWidth: true
  implicitHeight: row.implicitHeight + 20

  // a Rectangle's gradient runs only across or down, so the card is drawn
  // as a shape, whose gradient can run corner to corner
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      strokeWidth: 0
      strokeColor: "transparent"

      fillGradient: LinearGradient {
        x1: 0
        y1: root.height
        x2: root.width
        y2: 0

        GradientStop {
          position: 0
          color: root.tints[0]

          Behavior on color {
            ColorAnimation {
              duration: Theme.base
            }
          }
        }

        GradientStop {
          position: 1
          color: root.tints[1]

          Behavior on color {
            ColorAnimation {
              duration: Theme.base
            }
          }
        }
      }

      PathRectangle {
        width: root.width
        height: root.height
        radius: Theme.radiusSection
      }
    }
  }

  // the heart needs the track's liked state, which Spotify is asked for here
  Component.onCompleted: Spotify.look()

  // reads the cover small, for its colours; never seen. A Canvas cannot
  // draw an Image item, so it draws a 16px grab of the one shown, which
  // spares fetching the cover twice
  Canvas {
    id: sampler

    // the grab, kept while its URL is in use
    property var grab: null

    function take(result: var) {
      if (grab)
        unloadImage(grab.url);
      grab = result;
      if (result)
        loadImage(result.url);
      requestPaint();
    }

    width: 16
    height: 16
    opacity: 0
    onImageLoaded: requestPaint()
    // the cover may be in before the canvas can draw
    onAvailableChanged: requestPaint()
    onPaint: {
      const ctx = getContext("2d");
      ctx.clearRect(0, 0, width, height);
      if (!grab || !isImageLoaded(grab.url)) {
        root.tints = [Theme.sectionBg, Theme.sectionBg];
        return;
      }
      ctx.drawImage(grab.url, 0, 0, width, height);
      root.tints = root.tintsOf(ctx.getImageData(0, 0, width, height).data);
    }
  }

  RowLayout {
    id: row
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.margins: 10
    spacing: 12

    // the cover often arrives after the title: the music glyph holds its
    // place until it does
    ClippingRectangle {
      implicitWidth: 72
      implicitHeight: 72
      radius: Theme.radiusControl
      color: Qt.rgba(0, 0, 0, 0.25)

      Glyph {
        anchors.centerIn: parent
        visible: cover.status !== Image.Ready
        text: Icons.music
        color: Theme.fg
        font.pixelSize: 28
      }

      Image {
        id: cover
        anchors.fill: parent
        source: root.player?.trackArtUrl ?? ""
        sourceSize: Qt.size(144, 144)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        opacity: status === Image.Ready ? 1 : 0
        // the old colours stay while the next cover loads, so a track
        // change goes colour to colour rather than through grey
        onStatusChanged: {
          if (status === Image.Ready)
            grabToImage(result => sampler.take(result), Qt.size(16, 16));
          else if (status !== Image.Loading)
            sampler.take(null);
        }

        Behavior on opacity {
          NumberAnimation {
            duration: Theme.base
          }
        }
      }
    }

    ColumnLayout {
      spacing: 0
      Layout.fillWidth: true

      Txt {
        text: root.player?.trackTitle || "Unknown track"
        color: Theme.fgBright
        font.pixelSize: 14
        font.bold: true
        elide: Text.ElideRight
        Layout.fillWidth: true
      }

      Txt {
        text: root.player?.trackArtist || "Unknown artist"
        font.pixelSize: 12
        elide: Text.ElideRight
        Layout.fillWidth: true
      }

      RowLayout {
        spacing: 0
        Layout.fillWidth: true
        Layout.topMargin: 6

        MediaControls {
          player: root.player
          size: 30
        }

        Item {
          Layout.fillWidth: true
        }

        Heart {
          uri: Spotify.current
        }
      }
    }
  }
}
