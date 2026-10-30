import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd

// The login screen's state: the lock's interface (LockContext) over greetd.
// greetd runs the PAM conversation; a secret prompt is answered with the
// typed password, any other prompt (an OTP, a question) is shown in the field
// and answered with what is typed next.
Scope {
  id: root

  // the account to log in; the greeter is a single-user machine's
  readonly property string user: Quickshell.env("QS_GREETER_USER") || "jack"
  // the session to start, e.g. start-hyprland
  readonly property string session: Quickshell.env("QS_GREETER_SESSION") || ""
  readonly property string desktop: Quickshell.env("QS_GREETER_DESKTOP") || "Hyprland"
  // no greetd socket: drawn for a look in a normal session, cannot log in
  readonly property bool preview: !Greetd.available

  // "idle" | "checking" | "prompt" | "failed" | "unlocking"
  property string state: "idle"
  property string buffer: ""
  property string message: ""
  // a non-password question from PAM, and whether its answer is shown
  property string prompt: ""
  property bool echo: false
  property bool capsLock: false
  readonly property bool fingerprint: false
  property int failures: 0
  // the password typed before the session asked for it
  property var pending: null

  signal unlocked

  function type(text: string) {
    if (state === "checking" || state === "unlocking")
      return;
    if (state === "failed")
      state = "idle";
    buffer += text;
    checkCaps();
  }

  function erase(all: bool) {
    if (state === "checking" || state === "unlocking")
      return;
    buffer = all ? "" : buffer.slice(0, -1);
    if (state === "failed")
      state = "idle";
  }

  function submit() {
    if (state === "checking" || state === "unlocking")
      return;
    if (state === "prompt") {
      state = "checking";
      const answer = buffer;
      buffer = "";
      Greetd.respond(answer);
      return;
    }
    if (buffer === "")
      return;
    if (preview) {
      fail("Preview: greetd is not running");
      return;
    }
    state = "checking";
    message = "";
    pending = buffer;
    Greetd.createSession(user);
  }

  function fail(text: string) {
    pending = null;
    prompt = "";
    echo = false;
    buffer = "";
    state = "failed";
    failures += 1;
    message = text;
    if (!preview)
      Greetd.cancelSession();
  }

  // called by the window once the exit animation has played. The session
  // type reaches pam_systemd: greetd would open a "tty" session, and logind
  // prefers an older tty login (a rescue on another VT) as the user's
  // display, which is where hypridle listens for loginctl lock-session
  function launch() {
    Greetd.launch([session], ["XDG_SESSION_TYPE=wayland", `XDG_SESSION_DESKTOP=${desktop}`, `XDG_CURRENT_DESKTOP=${desktop}`]);
  }

  function checkCaps() {
    if (!caps.running)
      caps.running = true;
  }

  Connections {
    target: Greetd

    function onAuthMessage(text, error, responseRequired, echoResponse) {
      if (!responseRequired) {
        root.message = text;
        return;
      }
      if (!echoResponse && root.pending !== null) {
        Greetd.respond(root.pending);
        root.pending = null;
        return;
      }
      root.prompt = text.trim();
      root.echo = echoResponse;
      root.buffer = "";
      root.state = "prompt";
    }

    function onAuthFailure(text) {
      root.fail(text && text !== "authentication failed" ? text : "That's not the password");
    }

    function onReadyToLaunch() {
      root.state = "unlocking";
      root.buffer = "";
      root.prompt = "";
      root.unlocked();
    }

    function onError(text) {
      root.fail(text);
    }
  }

  Process {
    id: caps
    command: ["hyprctl", "devices", "-j"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          root.capsLock = JSON.parse(text).keyboards.some(k => k.main && k.capsLock);
        } catch (e) {}
      }
    }
  }

  Component.onCompleted: checkCaps()
}
