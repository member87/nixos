import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

// Authentication state shared by the lock surfaces of every screen.
// Password and fingerprint are two separate PAM conversations (see
// hosts/common/base/services/lockscreen.nix): one stack with both would make
// the password wait for the fingerprint reader to time out.
Scope {
  id: root

  readonly property string user: Quickshell.env("USER") ?? ""
  // always the password here; GreeterContext may ask other questions
  readonly property string prompt: ""
  readonly property bool echo: false
  readonly property bool preview: false
  // the process starts when the screen locks: notifications after this came
  // in while you were away
  readonly property real lockedAt: Date.now()

  // "idle" | "checking" | "failed" | "unlocking"
  property string state: "idle"
  property string buffer: ""
  property string message: ""
  property bool capsLock: false
  // only hosts with fprintd get the second PAM service
  property bool fingerprint: false
  // bumped on every wrong password so each surface can shake its field
  property int failures: 0

  // the lock window plays its exit animation, then releases the session
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
    if (buffer === "" || state === "checking" || state === "unlocking")
      return;
    state = "checking";
    message = "";
    // start() refuses (and completes nothing) when the PAM config is missing
    if (!password.start())
      fail("Could not start authentication");
  }

  function fail(text: string) {
    buffer = "";
    state = "failed";
    failures += 1;
    message = text;
  }

  function succeed() {
    state = "unlocking";
    buffer = "";
    password.abort();
    fprint.abort();
    unlocked();
  }

  function checkCaps() {
    if (!caps.running)
      caps.running = true;
  }

  PamContext {
    id: password
    // "login" until the check below confirms the dedicated service exists,
    // so a home-manager switch ahead of the system one never locks you out
    config: "login"

    onPamMessage: {
      if (responseRequired) {
        respond(root.buffer);
      } else if (messageIsError) {
        root.message = message;
      }
    }

    onCompleted: result => {
      if (result === PamResult.Success)
        root.succeed();
      else if (result === PamResult.MaxTries)
        root.fail("Too many attempts, wait a moment");
      else if (result === PamResult.Error)
        root.fail("Authentication failed to run, try again");
      else
        root.fail("That's not the password");
    }
  }

  // Runs alongside the password conversation; whichever succeeds first
  // unlocks. pam_fprintd scans until a finger matches or it gives up (timeout,
  // too many misses), and a give-up starts a new scan. One that gives up at
  // once means no reader or no enrolled finger: stop and leave the password.
  PamContext {
    id: fprint

    property real startedAt: 0

    config: "quickshell-lock-fprint"
    active: root.fingerprint && root.state !== "unlocking"
    onActiveChanged: {
      if (active)
        startedAt = Date.now();
    }

    onCompleted: result => {
      if (result === PamResult.Success)
        root.succeed();
      else if (Date.now() - startedAt < 2000)
        root.fingerprint = false;
      else if (root.state !== "unlocking")
        rescan.start();
    }
  }

  Timer {
    id: rescan
    interval: 1000
    onTriggered: {
      if (root.fingerprint && root.state !== "unlocking" && !fprint.active)
        fprint.start();
    }
  }

  // the dedicated PAM services; fingerprint only exists where fprintd is on
  Process {
    running: true
    command: ["ls", "/etc/pam.d/quickshell-lock", "/etc/pam.d/quickshell-lock-fprint"]
    stdout: StdioCollector {
      onStreamFinished: {
        const found = text.split("\n");
        if (found.includes("/etc/pam.d/quickshell-lock") && !password.active)
          password.config = "quickshell-lock";
        root.fingerprint = found.includes("/etc/pam.d/quickshell-lock-fprint");
      }
    }
  }

  // there is no caps lock state in Qt key events; ask the compositor
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
