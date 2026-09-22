package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"strconv"
	"sync"

	"github.com/metacubex/mihomo/listener/inbound"
	"github.com/metacubex/mihomo/tunnel"
)

// A probe listener is a temporary loopback mixed (HTTP/SOCKS) inbound pinned
// to one proxy by name. Connections through it resolve via the listener's
// special proxy (tunnel.resolveMetadata), bypassing rules and every group's
// current selection, so the app can test a single node without switching
// the user's active route or disturbing existing connections.

const probeListenerName = "panorama-probe"

type probeListenerParams struct {
	Proxy string `json:"proxy"`
}

type probeListenerResult struct {
	Port  int    `json:"port,omitempty"`
	Error string `json:"error,omitempty"`
}

var (
	probeLock     sync.Mutex
	probeListener *inbound.Mixed
)

func startProbeListener(proxyName string) (int, error) {
	if proxyName == "" {
		return 0, errors.New("proxy name is empty")
	}
	if _, ok := tunnel.Proxies()[proxyName]; !ok {
		return 0, fmt.Errorf("proxy %s not found", proxyName)
	}

	probeLock.Lock()
	defer probeLock.Unlock()
	closeProbeListenerLocked()

	listener, err := inbound.NewMixed(&inbound.MixedOption{
		BaseOption: inbound.BaseOption{
			NameStr:      probeListenerName,
			Listen:       "127.0.0.1",
			Port:         "0",
			SpecialProxy: proxyName,
		},
		// An explicit empty list gives this listener its own no-auth store.
		// Left nil, it falls back to the global store, and mihomo then also
		// applies the global authentication users and lan-allowed-ips to
		// it, so a user's LAN/auth settings could make probes fail. Safe
		// because it only binds to loopback.
		Users: inbound.AuthUsers{},
	})
	if err != nil {
		return 0, err
	}
	if err := listener.Listen(tunnel.Tunnel); err != nil {
		_ = listener.Close()
		return 0, err
	}
	_, portString, err := net.SplitHostPort(listener.Address())
	if err != nil {
		_ = listener.Close()
		return 0, err
	}
	port, err := strconv.Atoi(portString)
	if err != nil || port == 0 {
		_ = listener.Close()
		return 0, fmt.Errorf("probe listener has no port: %s", listener.Address())
	}
	probeListener = listener
	return port, nil
}

func stopProbeListener() {
	probeLock.Lock()
	defer probeLock.Unlock()
	closeProbeListenerLocked()
}

func closeProbeListenerLocked() {
	if probeListener == nil {
		return
	}
	if err := probeListener.Close(); err != nil {
		logError("close probe listener: %v", err)
	}
	probeListener = nil
}

// handleStartProbeListener always answers with JSON so the Dart side can
// tell a port from a reason: {"port": 51234} or {"error": "..."}.
func handleStartProbeListener(paramsString string) string {
	var params probeListenerParams
	result := probeListenerResult{}
	if err := json.Unmarshal([]byte(paramsString), &params); err != nil {
		result.Error = err.Error()
	} else if port, err := startProbeListener(params.Proxy); err != nil {
		result.Error = err.Error()
	} else {
		result.Port = port
	}
	data, _ := json.Marshal(result)
	return string(data)
}

func handleStopProbeListener() bool {
	stopProbeListener()
	return true
}
