import QtQuick
import QtQuick.Shapes
import qs.common

// A popout grown out of the bar's bottom edge: the bar's own colour, flush
// against it, its top corners curving out into the bar and its bottom ones
// rounded, so bar and popout read as one surface. Its outline continues the
// bar's bottom line down its sides and round its bottom; the window starts
// on that line, so the popout covers it where the two join. The window is
// `ear` px wider than the panel on each side for the outward curves; set the
// window's `mask` to `area`.
//
// open() runs it down out of the bar, close() back up into it and then
// signals retracted(), when the window can go. A window that keeps its
// largest size sets `targetHeight` to the content's and `smooth`: the panel
// then eases to each new height (a page, a list unfolding) instead of
// jumping, where a resized window could only jump.
Item {
  id: root

  default property alias content: panel.data
  property int radius: Theme.radiusPanel
  readonly property int ear: radius
  readonly property alias panel: panel
  // where the panel rests: the window's input mask. Not the panel itself,
  // which slides; a mask follows only its item's own geometry, so one on the
  // panel stays where the slide began, out of sight, and takes no input.
  readonly property alias area: area
  property real targetHeight: height
  property bool smooth: false
  // the drawn height; eased once the panel is out, so what loads as it
  // opens does not stretch it on the way down
  property real shown: targetHeight
  property bool settled: false

  // out of the bar, or on its way
  property bool out: false
  signal retracted

  function open() {
    // mid-close it turns back from where it is
    if (retract.running) {
      retract.stop();
      out = true;
      drop.restart();
      return;
    }
    if (out)
      return;
    out = true;
    settled = false;
    body.y = -body.height;
    drop.restart();
  }

  function close() {
    if (!out)
      return;
    out = false;
    settled = false;
    drop.stop();
    retract.restart();
  }

  // the window went without close() (a dismissed popup): start afresh
  function reset() {
    drop.stop();
    retract.stop();
    out = false;
    settled = false;
  }

  Behavior on shown {
    enabled: root.smooth && root.settled
    NumberAnimation {
      duration: Theme.base
      easing.type: Theme.easeOut
    }
  }

  anchors.fill: parent
  // the part still inside the bar is hidden while it slides
  clip: true

  Item {
    id: area
    x: root.ear
    width: parent.width - root.ear * 2
    height: root.shown
  }

  Item {
    id: body
    width: parent.width
    height: root.shown

    Shape {
      anchors.fill: parent
      preferredRendererType: Shape.CurveRenderer

      // the fill, over the whole top row: it hides the bar's line where the
      // popout joins the bar
      ShapePath {
        fillColor: Theme.barOpaque
        strokeColor: "transparent"
        strokeWidth: 0
        startX: 0
        startY: 0

        // into the bar on the left
        PathArc {
          x: root.ear
          y: root.ear
          radiusX: root.ear
          radiusY: root.ear
          direction: PathArc.Clockwise
        }
        PathLine {
          x: root.ear
          y: body.height - root.radius
        }
        PathArc {
          x: root.ear + root.radius
          y: body.height
          radiusX: root.radius
          radiusY: root.radius
          direction: PathArc.Counterclockwise
        }
        PathLine {
          x: body.width - root.ear - root.radius
          y: body.height
        }
        PathArc {
          x: body.width - root.ear
          y: body.height - root.radius
          radiusX: root.radius
          radiusY: root.radius
          direction: PathArc.Counterclockwise
        }
        PathLine {
          x: body.width - root.ear
          y: root.ear
        }
        // and into the bar on the right
        PathArc {
          x: body.width
          y: 0
          radiusX: root.ear
          radiusY: root.ear
          direction: PathArc.Clockwise
        }
        PathLine {
          x: 0
          y: 0
        }
      }

      // the outline, half a pixel in so it lands on whole pixels; open at the
      // top, where it runs into the bar's own line
      ShapePath {
        fillColor: "transparent"
        strokeColor: Theme.border
        strokeWidth: 1
        startX: 0
        startY: 0.5

        PathArc {
          x: root.ear + 0.5
          y: root.ear + 0.5
          radiusX: root.ear + 0.5
          radiusY: root.ear
          direction: PathArc.Clockwise
        }
        PathLine {
          x: root.ear + 0.5
          y: body.height - 0.5 - root.radius
        }
        PathArc {
          x: root.ear + 0.5 + root.radius
          y: body.height - 0.5
          radiusX: root.radius
          radiusY: root.radius
          direction: PathArc.Counterclockwise
        }
        PathLine {
          x: body.width - root.ear - 0.5 - root.radius
          y: body.height - 0.5
        }
        PathArc {
          x: body.width - root.ear - 0.5
          y: body.height - 0.5 - root.radius
          radiusX: root.radius
          radiusY: root.radius
          direction: PathArc.Counterclockwise
        }
        PathLine {
          x: body.width - root.ear - 0.5
          y: root.ear + 0.5
        }
        PathArc {
          x: body.width
          y: 0.5
          radiusX: root.ear + 0.5
          radiusY: root.ear
          direction: PathArc.Clockwise
        }
      }
    }

    Item {
      id: panel
      x: root.ear
      width: parent.width - root.ear * 2
      height: parent.height
    }
  }

  NumberAnimation {
    id: drop
    target: body
    property: "y"
    to: 0
    duration: Theme.enter
    easing.type: Theme.easeOut
    onFinished: root.settled = true
  }

  SequentialAnimation {
    id: retract
    NumberAnimation {
      target: body
      property: "y"
      to: -body.height
      duration: Theme.exit
      easing.type: Theme.easeIn
    }
    ScriptAction {
      script: root.retracted()
    }
  }
}
