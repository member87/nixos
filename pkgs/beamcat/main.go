// Command beamcat carries one BeamMP server port, TCP and UDP both, over a tailcat tunnel.
//
// The tailcat CLI's serve and forward commands carry TCP only
// (https://github.com/tailscale/tailcat/issues/122), and BeamMP sends vehicle updates
// over UDP on the same port as its TCP session. This is the library's OnUDP/DialUDPPort
// wired up for that one port.
//
//	beamcat serve -state DIR [-target 127.0.0.1:30814] [-port 30814]
//	beamcat connect [-listen 127.0.0.1:30814] [-port 30814] ADDRESS
package main

import (
	"cmp"
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"log"
	"net"
	"net/netip"
	"os"
	"os/signal"
	"path/filepath"
	"sync"
	"syscall"
	"time"

	"github.com/tailscale/tailcat"
	"tailscale.com/tailcfg"
	"tailscale.com/types/key"
	"tailscale.com/types/logger"
	"tailscale.com/wgengine/filter"
)

// flowIdle is how long a UDP flow may go quiet before either side drops it. BeamMP binds
// a player to the first UDP source address it sees and ignores packets from any other, so
// a flow that is dropped and recreated mid-session (with a new local source port on the
// server side) desyncs that player. Keep it far above any pause in a session.
const flowIdle = time.Hour

func main() {
	log.SetFlags(0)
	if len(os.Args) < 2 {
		usage()
	}
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	var err error
	switch os.Args[1] {
	case "serve":
		err = serve(ctx, os.Args[2:])
	case "connect":
		err = connect(ctx, os.Args[2:])
	default:
		usage()
	}
	if err != nil && !errors.Is(err, context.Canceled) {
		log.Fatal(err)
	}
}

func usage() {
	fmt.Fprint(os.Stderr, `usage:
  beamcat serve -state DIR [-target 127.0.0.1:30814] [-port 30814]
      Serve a BeamMP server over tailcat. The address is written to DIR/address and
      stays the same across restarts.
  beamcat connect [-listen 127.0.0.1:30814] [-port 30814] ADDRESS
      Connect to a beamcat server, then Direct Connect to 127.0.0.1:30814 in BeamMP.
`)
	os.Exit(2)
}

func tunnelLogf(verbose bool) logger.Logf {
	if verbose {
		return log.Printf
	}
	return logger.Discard
}

// state is the server identity kept across restarts, so its address stays valid.
type state struct {
	Key          key.NodePrivate      `json:"key"`
	PresharedKey tailcat.PresharedKey `json:"psk"`
	// Region is the DERP region picked on first start; the address names it, so a
	// later start must listen there again.
	Region tailcfg.DERPRegionID `json:"region,omitempty"`
}

func loadState(path string) (*state, error) {
	b, err := os.ReadFile(path)
	if errors.Is(err, os.ErrNotExist) {
		return &state{Key: key.NewNode(), PresharedKey: tailcat.NewPresharedKey()}, nil
	}
	if err != nil {
		return nil, err
	}
	var st state
	if err := json.Unmarshal(b, &st); err != nil {
		return nil, fmt.Errorf("%s: %w", path, err)
	}
	return &st, nil
}

// writeFile replaces path atomically: a crash mid-write must not lose the key.
func writeFile(path string, data []byte, mode os.FileMode) error {
	tmp := path + ".tmp"
	if err := os.WriteFile(tmp, data, mode); err != nil {
		return err
	}
	return os.Rename(tmp, path)
}

func serve(ctx context.Context, args []string) error {
	fs := flag.NewFlagSet("serve", flag.ExitOnError)
	stateDir := fs.String("state", "", "directory for the server key and address (required)")
	target := fs.String("target", "127.0.0.1:30814", "BeamMP server address")
	port := fs.Uint("port", 30814, "port served over the tunnel")
	verbose := fs.Bool("verbose", false, "log tunnel diagnostics")
	fs.Parse(args)
	if *stateDir == "" || fs.NArg() != 0 {
		usage()
	}
	tcpTarget := *target
	udpTarget, err := net.ResolveUDPAddr("udp", *target)
	if err != nil {
		return fmt.Errorf("-target: %w", err)
	}
	tunnelPort := uint16(*port)

	statePath := filepath.Join(*stateDir, "key.json")
	st, err := loadState(statePath)
	if err != nil {
		return err
	}

	// Pick the relay region here rather than leaving it to Start: the address Start
	// reports embeds the region without its ID, and a saved key must come back in the
	// region its address names.
	rci := &tailcat.ConnInfo{RegionID: cmp.Or(st.Region, -1)}
	if err := rci.Expand(ctx, tailcat.ExpandForServer); err != nil {
		return fmt.Errorf("picking a relay region: %w", err)
	}
	region := rci.Region[0]
	if st.Region != region.RegionID {
		st.Region = region.RegionID
		b, err := json.Marshal(st)
		if err != nil {
			return err
		}
		if err := writeFile(statePath, b, 0o600); err != nil {
			return err
		}
	}

	ports := []filter.PortRange{{First: tunnelPort, Last: tunnelPort}}
	s := &tailcat.Server{
		Key:            st.Key,
		PresharedKey:   st.PresharedKey,
		Region:         region,
		Logf:           tunnelLogf(*verbose),
		ServedTCPPorts: ports,
		ServedUDPPorts: ports,
		UDPIdleTimeout: flowIdle,
		OnTCP: func(p uint16) func(net.Conn) {
			if p != tunnelPort {
				return nil
			}
			return func(c net.Conn) {
				t, err := net.Dial("tcp", tcpTarget)
				if err != nil {
					log.Printf("dialing BeamMP server: %v", err)
					c.Close()
					return
				}
				tailcat.ProxyConns(c, t)
			}
		},
		// One local socket per tunnel flow, so each player keeps the stable UDP source
		// address BeamMP pins them to.
		OnUDP: func(p uint16) func(tailcat.ConnPacketConn) {
			if p != tunnelPort {
				return nil
			}
			return func(c tailcat.ConnPacketConn) {
				t, err := net.DialUDP("udp", nil, udpTarget)
				if err != nil {
					log.Printf("dialing BeamMP server: %v", err)
					c.Close()
					return
				}
				tailcat.ProxyPacketConns(c, t)
			}
		},
	}
	if err := s.Start(); err != nil {
		return err
	}
	defer s.Close()

	ci, err := tailcat.ParseAddr(s.TailcatAddr())
	if err != nil {
		return err
	}
	// The short form names the region by ID; clients fetch its relay details, so the
	// address survives Tailscale renumbering a relay.
	short := tailcat.ConnInfo{
		ServerPublic:      ci.ServerPublic,
		ServerDiscoPublic: ci.ServerDiscoPublic,
		PresharedKey:      ci.PresharedKey,
		RegionID:          region.RegionID,
	}
	addrPath := filepath.Join(*stateDir, "address")
	if err := writeFile(addrPath, []byte(string(short.Addr())+"\n"), 0o640); err != nil {
		return err
	}
	// The address is the credential, so it goes to a file, not the journal.
	log.Printf("serving %s over tailcat (relay %s); address in %s", *target, region.RegionCode, addrPath)

	<-ctx.Done()
	return ctx.Err()
}

func connect(ctx context.Context, args []string) error {
	fs := flag.NewFlagSet("connect", flag.ExitOnError)
	listen := fs.String("listen", "127.0.0.1:30814", "local address BeamMP connects to")
	port := fs.Uint("port", 30814, "port served over the tunnel")
	verbose := fs.Bool("verbose", false, "log tunnel diagnostics")
	fs.Parse(args)
	if fs.NArg() != 1 {
		usage()
	}
	tunnelPort := uint16(*port)

	cl := &tailcat.Client{Server: tailcat.Addr(fs.Arg(0)), Logf: tunnelLogf(*verbose)}
	if _, err := tailcat.ParseAddr(cl.Server); err != nil {
		return fmt.Errorf("bad address: %w", err)
	}
	defer cl.Close()

	tcpLn, err := net.Listen("tcp", *listen)
	if err != nil {
		return err
	}
	defer tcpLn.Close()
	udpAddr, err := net.ResolveUDPAddr("udp", *listen)
	if err != nil {
		return err
	}
	udpLn, err := net.ListenUDP("udp", udpAddr)
	if err != nil {
		return err
	}
	defer udpLn.Close()

	log.Printf("connecting to the server...")
	for {
		_, err := cl.Ping(ctx)
		if err == nil {
			break
		}
		if ctx.Err() != nil {
			return ctx.Err()
		}
		log.Printf("server not reachable yet (%v), retrying", err)
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-time.After(5 * time.Second):
		}
	}
	log.Printf("connected. In BeamMP, Direct Connect to %s and keep this window open.", *listen)

	go keepAlive(ctx, cl)
	go serveUDP(ctx, cl, udpLn, tunnelPort)
	go func() {
		<-ctx.Done()
		tcpLn.Close()
		udpLn.Close()
	}()

	for {
		c, err := tcpLn.Accept()
		if err != nil {
			if ctx.Err() != nil {
				return ctx.Err()
			}
			return err
		}
		go func() {
			dctx, cancel := context.WithTimeout(ctx, 15*time.Second)
			defer cancel()
			t, err := cl.DialTCPPort(dctx, tunnelPort)
			if err != nil {
				log.Printf("opening a connection to the server: %v", err)
				c.Close()
				return
			}
			tailcat.ProxyConns(c, t)
		}()
	}
}

// keepAlive re-registers with the server and reports the path. The server forgets its
// clients when it restarts, and the library registers only once per Client
// (https://github.com/tailscale/tailcat/issues/159), so without the repeated ping a
// server restart would leave this side hanging. The disco ping also keeps upgrading a
// relayed path to a direct one.
func keepAlive(ctx context.Context, cl *tailcat.Client) {
	t := time.NewTicker(20 * time.Second)
	defer t.Stop()
	lastPath, reachable := "", true
	for {
		_, err := cl.Ping(ctx)
		if ctx.Err() != nil {
			return
		}
		switch {
		case err != nil && reachable:
			log.Printf("lost the server (%v); will keep trying", err)
			reachable, lastPath = false, ""
		case err == nil && !reachable:
			log.Printf("server reachable again")
			reachable = true
		}
		if err == nil {
			if res, err := cl.DiscoPing(ctx); err == nil {
				path := "relayed through DERP " + res.DERPRegionCode + " (expect lag)"
				if res.Endpoint != "" {
					path = "direct to " + res.Endpoint
				}
				if path != lastPath {
					log.Printf("path: %s", path)
					lastPath = path
				}
			}
		}
		select {
		case <-ctx.Done():
			return
		case <-t.C:
		}
	}
}

type udpFlow struct {
	pc       tailcat.ConnPacketConn
	mu       sync.Mutex
	lastUsed time.Time
}

func (f *udpFlow) touch() {
	f.mu.Lock()
	f.lastUsed = time.Now()
	f.mu.Unlock()
}

func (f *udpFlow) idleSince(now time.Time) time.Duration {
	f.mu.Lock()
	defer f.mu.Unlock()
	return now.Sub(f.lastUsed)
}

// serveUDP gives each local source address its own tunnel flow, so the server sees one
// stable source per player.
func serveUDP(ctx context.Context, cl *tailcat.Client, ln *net.UDPConn, port uint16) {
	var mu sync.Mutex
	flows := map[netip.AddrPort]*udpFlow{}

	go func() {
		t := time.NewTicker(time.Minute)
		defer t.Stop()
		for {
			select {
			case <-ctx.Done():
				return
			case now := <-t.C:
				mu.Lock()
				for src, f := range flows {
					if f.idleSince(now) > flowIdle {
						f.pc.Close()
						delete(flows, src)
					}
				}
				mu.Unlock()
			}
		}
	}()

	warnedLarge := false
	buf := make([]byte, 64<<10)
	for {
		n, src, err := ln.ReadFromUDPAddrPort(buf)
		if err != nil {
			if ctx.Err() == nil {
				log.Printf("reading UDP: %v", err)
			}
			return
		}
		if n > tailcat.MaxUDPPayload && !warnedLarge {
			log.Printf("warning: %d-byte UDP packet is over the tunnel's %d-byte limit and may be dropped", n, tailcat.MaxUDPPayload)
			warnedLarge = true
		}

		mu.Lock()
		f := flows[src]
		mu.Unlock()
		if f == nil {
			dctx, cancel := context.WithTimeout(ctx, 10*time.Second)
			pc, err := cl.DialUDPPort(dctx, port)
			cancel()
			if err != nil {
				log.Printf("opening a UDP flow to the server: %v", err)
				continue
			}
			f = &udpFlow{pc: pc, lastUsed: time.Now()}
			mu.Lock()
			flows[src] = f
			mu.Unlock()
			go func() {
				b := make([]byte, 64<<10)
				for {
					n, err := pc.Read(b)
					if err != nil {
						mu.Lock()
						if flows[src] == f {
							delete(flows, src)
						}
						mu.Unlock()
						return
					}
					f.touch()
					ln.WriteToUDPAddrPort(b[:n], src)
				}
			}()
		}
		f.touch()
		f.pc.Write(buf[:n])
	}
}
