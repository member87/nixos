import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd

// The login screen's state: the lock's interface (LockContext) over greetd.
// greetd runs the PAM conversation; a secret prompt is answered with the
// typed password, any other prompt (an OTP, a question) is shown in the field
// and answered with what is typed next.
//
// With a fingerprint reader (greeter.nix) greetd's stack scans before it asks
// for the password, and greetd cannot interrupt a running module. So a scan
// starts with the screen, and the first key typed stops fprintd, which ends
// the scan and lets the password question through; an empty field scans again.
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
  // greetd's stack starts with pam_fprintd (greeter.nix)
  readonly property bool hasReader: Quickshell.env("QS_GREETER_FINGERPRINT") === "1" && !preview
  // false once a scan ended without starting: no reader, or no finger enrolled
  property bool reader: hasReader
  // the hint: typing switches to the password
  readonly property bool fingerprint: reader && conversation === "scanning" && buffer === ""
  property int failures: 0
  // the password typed before the session asked for it
  property var pending: null

  // greetd's side, apart from what the screen shows: "none" | "scanning"
  // (pam_fprintd, ahead of the password) | "held" (the password question,
  // kept until Enter) | "answering"
  property string conversation: "none"
  // pam_fprintd has said it is scanning, so stopping fprintd ends the scan;
  // before that, a stop could land ahead of it and fprintd would come back
  property bool scanStarted: false
  property bool scanStopped: false

  signal unlocked

  function type(text: string) {
    if (state === "checking" || state === "unlocking")
      return;
    if (state === "failed")
      state = "idle";
    buffer += text;
    stopScan();
    checkCaps();
  }

  function erase(all: bool) {
    if (state === "checking" || state === "unlocking")
      return;
    buffer = all ? "" : buffer.slice(0, -1);
    if (state === "failed")
      state = "idle";
    if (buffer === "")
      rescan.restart();
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
    if (conversation === "held") {
      conversation = "answering";
      Greetd.respond(buffer);
      return;
    }
    pending = buffer;
    // when scanning, the question follows once type() has stopped the scan
    if (conversation === "none")
      begin();
  }

  function begin() {
    conversation = hasReader ? "scanning" : "answering";
    scanStarted = false;
    scanStopped = false;
    Greetd.createSession(user);
  }

  function stopScan() {
    if (conversation !== "scanning" || !scanStarted || scanStopped || buffer === "")
      return;
    scanStopped = true;
    stopFprintd.running = true;
  }

  function fail(text: string) {
    pending = null;
    conversation = "none";
    prompt = "";
    echo = false;
    buffer = "";
    state = "failed";
    failures += 1;
    message = text;
    if (!preview)
      Greetd.cancelSession();
    rescan.restart();
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
      let afterScan = false;
      if (root.conversation === "scanning") {
        if (!responseRequired) {
          // pam_fprintd's "place your finger" and misses; the hint covers them
          root.scanStarted = true;
          root.stopScan();
          return;
        }
        // the scan is over without a match; this is the password stack
        if (!root.scanStarted)
          root.reader = false;
        else
          rescan.restart();
        root.conversation = "answering";
        afterScan = true;
      }
      if (!responseRequired) {
        root.message = text;
        return;
      }
      if (!echoResponse && root.pending !== null) {
        Greetd.respond(root.pending);
        root.pending = null;
        return;
      }
      if (!echoResponse && afterScan) {
        root.conversation = "held";
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

  // a scan again, with an empty field: after a give-up, a wrong password, or
  // the password erased. A held question is cancelled a tick before the new
  // session: quickshell does not wait for greetd's reply to the cancel, and
  // would read it as the next session's success
  Timer {
    id: rescan
    interval: 1000
    onTriggered: {
      if (!root.reader || root.buffer !== "" || (root.state !== "idle" && root.state !== "failed"))
        return;
      if (root.conversation === "held") {
        Greetd.cancelSession();
        root.conversation = "none";
        restart();
      } else if (root.conversation === "none") {
        root.begin();
      }
    }
  }

  // pam_fprintd gives up when fprintd leaves the bus; polkit lets the
  // greeter user stop it (greeter.nix), and the next scan starts it again
  Process {
    id: stopFprintd
    command: ["systemctl", "stop", "fprintd.service"]
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

  Component.onCompleted: {
    checkCaps();
    if (hasReader)
      begin();
  }
}
