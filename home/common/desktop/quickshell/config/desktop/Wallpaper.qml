import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common

// The wallpaper (quickshell/default.nix hands its path over in
// QS_WALLPAPER), scaled to cover the screen and centred; the desktop's
// layout is measured against it drawn that way. One per screen, on the
// background layer, under the desktop and the windows. Without a path, or
// until the image is decoded, the ground colour alone.
PanelWindow {
  id: root

  required property var modelData

  screen: modelData
  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "quickshell-wallpaper"
  WlrLayershell.layer: WlrLayer.Background
  color: Theme.wallpaper

  Image {
    anchors.fill: parent
    source: Paths.wallpaper === "" ? "" : `file://${Paths.wallpaper}`
    // decoded at the screen's pixel size, not the file's
    sourceSize: Qt.size(root.width * root.modelData.devicePixelRatio, root.height * root.modelData.devicePixelRatio)
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    cache: false
    smooth: true
  }
}
