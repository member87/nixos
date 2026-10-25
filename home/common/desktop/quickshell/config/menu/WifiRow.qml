import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import qs.common
import qs.components
import qs.services

// one network in range: click to join; unknown secured networks ask for
// the password inline
ColumnLayout {
  id: row

  required property var modelData
  readonly property int strength: Math.round(modelData.signalStrength * 100)
  readonly property bool busy: modelData.stateChanging || modelData.state === ConnectionState.Connecting
  property bool asking: false
  property bool triedPassword: false
  property string error: ""

  function activate() {
    error = "";
    if (modelData.known || !Net.secured(modelData)) {
      modelData.connect();
    } else if (Net.needsPassword(modelData)) {
      asking = !asking;
      if (asking)
        password.forceActiveFocus();
    } else {
      error = "802.1X network: set it up with nmtui";
    }
  }

  function submit() {
    if (password.text.length < 8)
      return;
    triedPassword = true;
    modelData.connectWithPsk(password.text);
    password.text = "";
    asking = false;
  }

  spacing: 4
  Layout.fillWidth: true

  Connections {
    target: row.modelData

    function onConnectionFailed(reason) {
      if (reason === ConnectionFailReason.NoSecrets && Net.needsPassword(row.modelData)) {
        row.error = row.triedPassword ? "Wrong password" : "";
        row.asking = true;
        password.forceActiveFocus();
      } else {
        row.error = `Could not connect: ${ConnectionFailReason.toString(reason)}`;
      }
    }
  }

  Clickable {
    Layout.fillWidth: true
    fill: true
    padX: 6
    padY: 5
    radius: 5
    spacing: 8
    enabled: !row.busy
    onClicked: row.activate()

    Glyph {
      text: Icons.wifi(row.strength, Net.secured(row.modelData))
      font.pixelSize: 16
      Layout.preferredWidth: 26
    }

    ColumnLayout {
      spacing: 0
      Layout.fillWidth: true

      Txt {
        text: row.modelData.name
        color: Theme.fgBright
        font.pixelSize: 12
        elide: Text.ElideRight
        Layout.fillWidth: true
      }

      Txt {
        text: row.busy ? "Connecting…" : row.modelData.known ? `Saved · ${Net.securityName(row.modelData)}` : Net.securityName(row.modelData)
        font.pixelSize: 12
      }
    }
  }

  RowLayout {
    visible: row.asking
    spacing: 8
    Layout.leftMargin: 40

    Rectangle {
      Layout.fillWidth: true
      implicitHeight: 28
      radius: 5
      color: Theme.bgSolid
      border.width: 1
      border.color: password.activeFocus ? Theme.accent : Theme.border

      TextInput {
        id: password
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        verticalAlignment: TextInput.AlignVCenter
        echoMode: TextInput.Password
        color: Theme.fgBright
        selectionColor: Theme.accent
        selectedTextColor: Theme.accentInk
        font.family: Theme.font
        font.pixelSize: 12
        clip: true
        onAccepted: row.submit()
        Keys.onEscapePressed: row.asking = false
      }

      Txt {
        visible: password.text === ""
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: "Password"
        font.pixelSize: 12
      }
    }

    TextButton {
      text: "Join"
      primary: true
      enabled: password.text.length >= 8
      onClicked: row.submit()
    }
  }

  Txt {
    visible: row.error !== ""
    text: row.error
    color: Theme.critical
    font.pixelSize: 12
    Layout.leftMargin: 40
  }
}
