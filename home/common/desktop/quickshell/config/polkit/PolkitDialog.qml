import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Polkit
import Quickshell.Wayland
import qs.common
import qs.components

// The polkit agent, replacing lxqt-policykit-agent: an app asking for admin
// rights gets this dialog over a dimmed screen. PAM may ask several things
// (on thor the fingerprint first, then the password); each prompt shows in
// the field, and its answer is sent with Enter.
Scope {
  id: root

  readonly property var flow: agent.flow
  property string answer: ""

  function submit() {
    if (flow && flow.isResponseRequired && answer !== "") {
      flow.submit(answer);
      answer = "";
    }
  }

  function cancel() {
    answer = "";
    flow?.cancelAuthenticationRequest();
  }

  PolkitAgent {
    id: agent
  }

  Connections {
    target: root.flow
    ignoreUnknownSignals: true

    function onAuthenticationFailed() {
      root.answer = "";
      shake.restart();
    }
  }

  PanelWindow {
    id: dialog

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    visible: agent.isActive && root.flow !== null
    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell-polkit"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    // the screen dims as the card rises into place
    color: "transparent"

    onVisibleChanged: {
      if (visible) {
        keys.forceActiveFocus();
        appear.restart();
      }
    }

    ParallelAnimation {
      id: appear
      ColorAnimation {
        target: dialog
        property: "color"
        from: "transparent"
        to: Qt.rgba(0, 0, 0, 0.55)
        duration: Theme.enter
        easing.type: Theme.easeOut
      }
      NumberAnimation {
        target: card
        property: "opacity"
        from: 0
        to: 1
        duration: Theme.enter
        easing.type: Theme.easeOut
      }
      NumberAnimation {
        target: nudge
        property: "y"
        from: 14
        to: 0
        duration: Theme.ms(260)
        easing.type: Theme.easeOut
      }
    }

    // a click outside the card cancels, like Escape
    MouseArea {
      anchors.fill: parent
      onClicked: root.cancel()
    }

    PopupShadow {
      anchors.fill: card
      radius: card.radius
      opacity: card.opacity
      transform: Translate {
        x: nudge.x
        y: nudge.y
      }
    }

    Rectangle {
      id: card

      anchors.centerIn: parent
      width: 460
      implicitHeight: body.implicitHeight + 48
      radius: Theme.radiusPanel
      color: Theme.bgSolid

      transform: Translate {
        id: nudge
      }

      // swallow clicks so they do not reach the cancelling area behind
      MouseArea {
        anchors.fill: parent
      }

      ColumnLayout {
        id: body
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 24
        spacing: 14

        RowLayout {
          spacing: 14

          Glyph {
            text: Icons.vpnLocked
            font.pixelSize: 30
            Layout.alignment: Qt.AlignTop
          }

          ColumnLayout {
            spacing: 4
            Layout.fillWidth: true

            Txt {
              text: "Authentication required"
              color: Theme.accent
              font.pixelSize: 16
              font.bold: true
            }

            Txt {
              text: root.flow?.message ?? ""
              color: Theme.fgBright
              font.pixelSize: 14
              wrapMode: Text.Wrap
              Layout.fillWidth: true
            }
          }
        }

        // who authenticates; several admins can be cycled through
        Clickable {
          id: who

          readonly property var identities: root.flow?.identities ?? []

          Layout.fillWidth: true
          fill: true
          padX: 12
          padY: 8
          radius: Theme.radiusControl + 2
          color: Theme.sectionBg
          enabled: identities.length > 1
          opacity: 1
          onClicked: {
            const i = identities.indexOf(root.flow.selectedIdentity);
            root.flow.selectedIdentity = identities[(i + 1) % identities.length];
          }

          Txt {
            text: `As ${root.flow?.selectedIdentity?.displayName || root.flow?.selectedIdentity?.string || ""}`
            color: Theme.fgBright
            font.pixelSize: 13
            Layout.fillWidth: true
          }

          Glyph {
            visible: who.identities.length > 1
            text: Icons.chevronDown
            color: Theme.fg
            font.pixelSize: 14
          }
        }

        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 44
          radius: Theme.radiusControl + 2
          color: Theme.sectionBg
          border.width: root.flow?.failed ? 1 : 0
          border.color: Theme.critical
          opacity: root.flow?.isResponseRequired ? 1 : 0.6

          Txt {
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            visible: root.answer === ""
            text: (root.flow?.inputPrompt || "Password").replace(/:\s*$/, "")
            font.pixelSize: 14
          }

          // the caret: typing goes here. It blinks as a text field's does,
          // and only while an answer is wanted.
          Rectangle {
            id: caret

            readonly property bool wanted: dialog.visible && !!root.flow?.isResponseRequired

            x: 14 + (root.answer === "" ? 0 : Math.min(answerText.paintedWidth, caret.parent.width - 28) + 2)
            anchors.verticalCenter: parent.verticalCenter
            width: 2
            height: 18
            radius: 1
            color: Theme.accent
            visible: wanted

            SequentialAnimation on opacity {
              running: caret.wanted
              loops: Animation.Infinite
              PropertyAction {
                value: 1
              }
              PauseAnimation {
                duration: 530
              }
              PropertyAction {
                value: 0
              }
              PauseAnimation {
                duration: 530
              }
            }
          }

          Txt {
            id: answerText
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            visible: root.answer !== ""
            text: root.flow?.responseVisible ? root.answer : "\u2022".repeat(root.answer.length)
            color: Theme.fgBright
            font.pixelSize: 15
            elide: Text.ElideLeft
          }
        }

        Txt {
          visible: text !== ""
          text: root.flow?.supplementaryMessage || (root.flow?.failed ? "That's not the password" : "")
          color: root.flow?.supplementaryIsError || root.flow?.failed ? Theme.critical : Theme.fg
          font.pixelSize: 13
          wrapMode: Text.Wrap
          Layout.fillWidth: true
        }

        RowLayout {
          spacing: 10
          Layout.alignment: Qt.AlignRight

          TextButton {
            text: "Cancel"
            onClicked: root.cancel()
          }

          TextButton {
            text: "Authenticate"
            primary: true
            enabled: !!root.flow?.isResponseRequired && root.answer !== ""
            onClicked: root.submit()
          }
        }
      }
    }

    // typing goes straight to the answer; there is no other input here
    Item {
      id: keys
      focus: true

      Keys.onPressed: e => {
        if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter)
          root.submit();
        else if (e.key === Qt.Key_Escape)
          root.cancel();
        else if (e.key === Qt.Key_Backspace)
          root.answer = e.modifiers & Qt.ControlModifier ? "" : root.answer.slice(0, -1);
        else if (e.text !== "" && e.text.charCodeAt(0) >= 32)
          root.answer += e.text;
        e.accepted = true;
      }
    }

    SequentialAnimation {
      id: shake
      NumberAnimation {
        target: nudge
        property: "x"
        to: -14
        duration: Theme.ms(50)
      }
      NumberAnimation {
        target: nudge
        property: "x"
        to: 12
        duration: Theme.ms(70)
      }
      NumberAnimation {
        target: nudge
        property: "x"
        to: 0
        duration: Theme.ms(60)
      }
    }
  }
}
