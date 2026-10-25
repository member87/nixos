# Cast this computer's audio to a Chromecast / Google speaker, for the bar.
#
#   bar-cast discover            one device per line: name<TAB>model<TAB>ip
#   bar-cast start IP NAME       cast until stdin closes or SIGTERM
#
# start makes a "Cast: NAME" output device (a PipeWire null sink) the
# default, so apps play into it and not the speakers; its monitor is encoded
# to MP3 by ffmpeg and served over HTTP, and the device is told to play that
# URL. On exit everything is put back: the device stops, the previous default
# output returns, the null sink goes. The bar keeps stdin open while casting,
# so if the bar dies the cast ends with it.

port=8095

discover() {
  # -r resolve, -t stop once the cache is listed, -p parseable; IPv4 only
  avahi-browse -rtp _googlecast._tcp 2>/dev/null |
    awk -F';' '$1 == "=" && $3 == "IPv4" {
      name = $10; model = $10
      sub(/.*"fn=/, "", name); sub(/".*/, "", name)
      sub(/.*"md=/, "", model); sub(/".*/, "", model)
      if (!seen[$8]++) print name "\t" model "\t" $8
    }'
}

# state for cleanup, which runs from the EXIT trap after start has returned
ip="" previous="" sink_module="" server="" reader=""

cleanup() {
  trap - EXIT INT TERM
  go-chromecast -a "$ip" stop >/dev/null 2>&1 || true
  if [ -n "$server" ]; then kill "$server" 2>/dev/null || true; fi
  if [ -n "$reader" ]; then kill "$reader" 2>/dev/null || true; fi
  if [ -n "$previous" ]; then pactl set-default-sink "$previous" 2>/dev/null || true; fi
  if [ -n "$sink_module" ]; then pactl unload-module "$sink_module" 2>/dev/null || true; fi
}

start() {
  ip=$1
  local name=$2 host
  previous=$(pactl get-default-sink)
  # the address of this machine on the route to the device
  host=$(ip -4 route get "$ip" | sed -n 's/.* src \([0-9.]*\).*/\1/p')

  trap cleanup EXIT INT TERM
  sink_module=$(pactl load-module module-null-sink sink_name=bar_cast \
    "sink_properties=device.description='Cast: $name'")

  pactl set-default-sink bar_cast
  # one ffmpeg per connection: the device may probe before it streams
  socat TCP-LISTEN:$port,reuseaddr,fork SYSTEM:"$0 serve" &
  server=$!

  go-chromecast -a "$ip" load "http://$host:$port/live.mp3" \
    --content-type audio/mpeg --detach

  echo "casting"
  # until the bar closes our stdin (stop, or the bar going away). In the
  # background with `wait`: bash runs a trap only between commands, and
  # `wait` returns on a signal where a foreground cat would not.
  cat >/dev/null &
  reader=$!
  wait "$reader"
}

# one HTTP response: headers, then the cast sink's monitor as MP3, forever
serve() {
  printf 'HTTP/1.0 200 OK\r\nContent-Type: audio/mpeg\r\nCache-Control: no-cache\r\n\r\n'
  exec ffmpeg -loglevel error -f pulse -i bar_cast.monitor \
    -ac 2 -ar 44100 -c:a libmp3lame -b:a 256k -f mp3 -
}

case "${1:-}" in
discover) discover ;;
start) start "$2" "$3" ;;
serve) serve ;;
*)
  echo "usage: bar-cast discover | start IP NAME" >&2
  exit 2
  ;;
esac
