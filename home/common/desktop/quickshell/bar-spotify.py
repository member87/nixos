"""Spotify Web API access for the bar's music drawer (config/bar/UpNext.qml).

bar-spotify link    signs in once, in the browser (authorization code with
                    PKCE, so no client secret), catches Spotify's redirect on
                    127.0.0.1:8898 and keeps the refresh token
bar-spotify token   prints a fresh access token as JSON:
                    {"access_token": ..., "expires_in": seconds}

The refresh token is kept in $XDG_STATE_HOME/quickshell/spotify.json, readable
by this user only; the shell never sees it, only the short-lived access
tokens. Exit 3: no client ID (default.nix); 4: not linked, or the link was
revoked; 1: Spotify could not be reached or refused.
"""

import base64
import hashlib
import html
import http.server
import json
import os
import secrets
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

CLIENT_ID = "@clientId@"
XDG_OPEN = "@xdgOpen@"
PORT = 8898
REDIRECT = f"http://127.0.0.1:{PORT}/callback"
SCOPES = "user-read-playback-state user-read-currently-playing user-library-read user-library-modify"
STATE_DIR = os.path.join(os.environ.get("XDG_STATE_HOME") or os.path.expanduser("~/.local/state"), "quickshell")
STORE = os.path.join(STATE_DIR, "spotify.json")
# how long the browser sign-in may take before giving up
PATIENCE = 300


class Refused(Exception):
    """Spotify answered, and said no (an expired or revoked grant)."""


def b64url(data):
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def keep(refresh_token):
    os.makedirs(STATE_DIR, exist_ok=True)
    tmp = STORE + ".tmp"
    fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w") as f:
        json.dump({"refresh_token": refresh_token}, f)
    os.replace(tmp, STORE)


def grant(fields):
    """POST to the token endpoint; the answer as a dict."""
    body = urllib.parse.urlencode({**fields, "client_id": CLIENT_ID}).encode()
    req = urllib.request.Request("https://accounts.spotify.com/api/token", data=body, headers={"Content-Type": "application/x-www-form-urlencoded"})
    try:
        with urllib.request.urlopen(req, timeout=15) as res:
            return json.load(res)
    except urllib.error.HTTPError as e:
        # 400 invalid_grant: the refresh token was revoked or has expired
        if e.code in (400, 401):
            raise Refused(e.read().decode(errors="replace")) from e
        raise


def token():
    try:
        with open(STORE) as f:
            refresh = json.load(f)["refresh_token"]
    except (OSError, ValueError, KeyError):
        return 4
    try:
        got = grant({"grant_type": "refresh_token", "refresh_token": refresh})
    except Refused as e:
        print(f"bar-spotify: the link was refused: {e}", file=sys.stderr)
        os.remove(STORE)
        return 4
    except OSError as e:
        print(f"bar-spotify: could not reach Spotify: {e}", file=sys.stderr)
        return 1
    # Spotify may hand out a new refresh token with each access token
    if got.get("refresh_token"):
        keep(got["refresh_token"])
    print(json.dumps({"access_token": got["access_token"], "expires_in": got.get("expires_in", 3600)}))
    return 0


def link():
    verifier = b64url(secrets.token_bytes(48))
    challenge = b64url(hashlib.sha256(verifier.encode()).digest())
    nonce = secrets.token_urlsafe(16)
    answer = {}

    class Callback(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            url = urllib.parse.urlsplit(self.path)
            query = urllib.parse.parse_qs(url.query)
            if url.path != "/callback" or query.get("state", [""])[0] != nonce:
                self.send_error(404)
                return
            answer.update({k: v[0] for k, v in query.items()})
            # exchanged before answering, so the page tells the truth
            if "code" in answer:
                try:
                    got = grant({"grant_type": "authorization_code", "code": answer["code"], "redirect_uri": REDIRECT, "code_verifier": verifier})
                    keep(got["refresh_token"])
                    answer["linked"] = True
                except (Refused, OSError) as e:
                    answer["error"] = f"Spotify would not exchange the code: {e}"
            page = "Spotify is linked. You can close this tab." if answer.get("linked") else f"Spotify did not link: {answer.get('error', 'no code')}."
            data = f"<!doctype html><meta charset=utf-8><title>bar-spotify</title><body style='font:16px monospace;background:#1d2021;color:#ebdbb2;padding:3em'>{html.escape(page)}".encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

        def log_message(self, *args):
            pass

    try:
        server = http.server.HTTPServer(("127.0.0.1", PORT), Callback)
    except OSError as e:
        print(f"bar-spotify: cannot listen on {REDIRECT}: {e}", file=sys.stderr)
        return 1
    query = urllib.parse.urlencode({
        "response_type": "code",
        "client_id": CLIENT_ID,
        "scope": SCOPES,
        "redirect_uri": REDIRECT,
        "code_challenge_method": "S256",
        "code_challenge": challenge,
        "state": nonce,
    })
    subprocess.Popen([XDG_OPEN, f"https://accounts.spotify.com/authorize?{query}"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    # the browser may open other connections first (a favicon, a preconnect)
    deadline = time.monotonic() + PATIENCE
    with server:
        while not answer and time.monotonic() < deadline:
            server.timeout = max(1, deadline - time.monotonic())
            server.handle_request()
    if not answer.get("linked"):
        print(f"bar-spotify: sign-in did not finish: {answer.get('error', 'timed out')}", file=sys.stderr)
        return 1
    return 0


def main():
    if len(sys.argv) != 2 or sys.argv[1] not in ("link", "token"):
        print("usage: bar-spotify link|token", file=sys.stderr)
        return 2
    if not CLIENT_ID:
        print("bar-spotify: no Spotify client ID is set (spotifyClientId in default.nix)", file=sys.stderr)
        return 3
    return link() if sys.argv[1] == "link" else token()


sys.exit(main())
