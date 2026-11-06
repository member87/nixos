import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.common
import qs.components
import qs.services

// The music drawer's right column: the next three tracks in Spotify's queue,
// each with its heart, and how many more follow. When the track changes the
// rows move up one place. Without the Web API (no client ID, not linked, not
// reachable) one line says so, and a button links it.
ColumnLayout {
  id: root

  readonly property int shown: 3

  function clock(seconds: real): string {
    const s = Math.max(0, Math.floor(seconds));
    return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
  }

  // the rows on screen follow Spotify.queue's first three. A queue that
  // moved up one place drops its first row, so the others slide up rather
  // than all being replaced.
  function sync() {
    const next = Spotify.queue.slice(0, shown);
    const same = (i, t) => rows.get(i).uri === t.uri;
    if (rows.count > 0 && next.length > 0 && rows.count > 1 && same(1, next[0]))
      rows.remove(0);
    let i = 0;
    while (i < next.length && i < rows.count && same(i, next[i]))
      i++;
    if (i < rows.count)
      rows.remove(i, rows.count - i);
    for (; i < next.length; i++)
      rows.append(next[i]);
  }

  spacing: 8

  Connections {
    target: Spotify
    function onQueueChanged() {
      root.sync();
    }
  }

  Component.onCompleted: sync()

  ListModel {
    id: rows
  }

  RowLayout {
    Layout.fillWidth: true

    Txt {
      text: "Up next"
      color: Theme.fgBright
      font.pixelSize: 12
      font.weight: Font.Medium
      Layout.fillWidth: true
    }

    Txt {
      visible: Spotify.status === "ready" && Spotify.queue.length > root.shown
      text: `+${Spotify.queue.length - root.shown} more`
      font.pixelSize: 12
    }
  }

  ListView {
    id: list

    visible: Spotify.status === "ready" && rows.count > 0
    Layout.fillWidth: true
    Layout.fillHeight: true
    interactive: false
    spacing: 8
    model: rows

    // the first row leaves upward, the others take its place, a new last
    // row fades in
    remove: Transition {
      ParallelAnimation {
        NumberAnimation {
          property: "opacity"
          to: 0
          duration: Theme.exit
          easing.type: Theme.easeIn
        }
        NumberAnimation {
          property: "y"
          to: -16
          duration: Theme.exit
          easing.type: Theme.easeIn
        }
      }
    }
    displaced: Transition {
      NumberAnimation {
        property: "y"
        duration: Theme.base
        easing.type: Theme.easeOut
      }
    }
    add: Transition {
      NumberAnimation {
        property: "opacity"
        from: 0
        to: 1
        duration: Theme.base
        easing.type: Theme.easeOut
      }
    }

    delegate: Item {
      id: row

      required property string uri
      required property string title
      required property string artist
      required property int length
      required property string art

      width: ListView.view.width
      height: 32

      HoverHandler {
        id: hover
      }

      // under the pointer the row lights and offers its heart
      Rectangle {
        x: -4
        width: parent.width + 8
        height: parent.height
        radius: Theme.radiusControl
        color: hover.hovered ? Theme.accentHover : "transparent"

        Behavior on color {
          ColorAnimation {
            duration: Theme.fast
          }
        }
      }

      RowLayout {
        anchors.fill: parent
        spacing: 8

        ClippingRectangle {
          implicitWidth: 28
          implicitHeight: 28
          radius: Theme.radiusControl
          color: Theme.sectionBg

          Image {
            anchors.fill: parent
            source: row.art
            sourceSize: Qt.size(56, 56)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
          }
        }

        ColumnLayout {
          spacing: 0
          Layout.fillWidth: true

          Txt {
            text: row.title
            color: Theme.fgBright
            font.pixelSize: 12
            elide: Text.ElideRight
            Layout.fillWidth: true
          }

          Txt {
            text: `${row.artist} · ${root.clock(row.length)}`
            font.pixelSize: 12
            font.features: {
              "tnum": 1,
              "cv11": 1
            }
            elide: Text.ElideRight
            Layout.fillWidth: true
          }
        }

        // a slot kept for it, so the lengths line up
        Item {
          implicitWidth: 22
          implicitHeight: 22

          Heart {
            anchors.centerIn: parent
            uri: row.uri
            size: 14
            implicitWidth: 22
            implicitHeight: 22
            opacity: Spotify.isLiked(row.uri) || hover.hovered ? 1 : 0
          }
        }
      }
    }
  }

  // in place of the rows: why there are none
  Txt {
    visible: !list.visible
    text: {
      switch (Spotify.status) {
      case "off":
        return "Set spotifyClientId in default.nix to see what plays next";
      case "unlinked":
        return "Link Spotify to see what plays next and like tracks";
      case "linking":
        return "Finish signing in to Spotify in the browser";
      case "error":
        return "Could not reach Spotify for Up next";
      case "ready":
        return "Nothing queued after this track";
      default:
        return "Finding what plays next…";
      }
    }
    font.pixelSize: 12
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
  }

  TextButton {
    visible: Spotify.status === "unlinked"
    text: "Link Spotify"
    onClicked: Spotify.link()
  }

  // the message sits under the heading, not centred in the column
  Item {
    visible: !list.visible
    Layout.fillHeight: true
  }
}
