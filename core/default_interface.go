package core

import (
	"net"
	"net/netip"
	"slices"
	"strings"
	"sync"

	"github.com/metacubex/mihomo/component/dialer"
)

var lastDefaultInterface struct {
	mu  sync.Mutex
	key string
}

// The TUN's finder skips its own adapter; addresses tell apart two networks on one adapter.
func defaultInterfaceKey() string {
	finder := dialer.DefaultInterfaceFinder.Load()
	if finder == nil {
		return ""
	}
	name := finder.FindInterfaceName(netip.IPv4Unspecified())
	ifc, err := net.InterfaceByName(name)
	if err != nil {
		return ""
	}
	addrs, err := ifc.Addrs()
	if err != nil {
		return ""
	}
	parts := make([]string, 0, len(addrs)+1)
	for _, addr := range addrs {
		parts = append(parts, addr.String())
	}
	slices.Sort(parts)
	return name + "|" + strings.Join(parts, ",")
}

func rememberDefaultInterface() {
	key := defaultInterfaceKey()
	lastDefaultInterface.mu.Lock()
	lastDefaultInterface.key = key
	lastDefaultInterface.mu.Unlock()
}

// An unreadable interface counts as moved, so a real change is never missed.
func defaultInterfaceMoved() bool {
	key := defaultInterfaceKey()
	lastDefaultInterface.mu.Lock()
	defer lastDefaultInterface.mu.Unlock()
	moved := key == "" || key != lastDefaultInterface.key
	lastDefaultInterface.key = key
	return moved
}
