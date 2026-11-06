package core

import (
	"net"
	"net/netip"
	"runtime"
	"sync"

	"github.com/metacubex/mihomo/component/dialer"
	"github.com/metacubex/mihomo/config"
	"github.com/metacubex/mihomo/constant/features"
)

// Until the TUN installs its interface finder, a socket binds no interface,
// so on desktop the ones made before or while it comes up (health checks, a
// hysteria2 session) loop into it once its routes are up: upload with no
// download until they die. Binding them to the physical interface for that
// window is what an explicit interface-name does, and it connected at once.
var egressPin struct {
	mu   sync.Mutex
	name string
}

var (
	// Android protects its sockets from the VPN instead.
	egressPinPlatform = runtime.GOOS == "windows" || runtime.GOOS == "darwin" || runtime.GOOS == "linux"
	findEgress        = physicalEgress
)

func wantsEgressPin(cfg *config.Config) bool {
	if !egressPinPlatform || features.Android || cfg == nil {
		return false
	}
	general := cfg.General
	return general.Interface == "" && general.Tun.Enable &&
		general.Tun.AutoDetectInterface && dialer.DefaultInterfaceFinder.Load() == nil
}

// pinEgress must run before the config lands: providers start their health
// checks while it applies.
func pinEgress(cfg *config.Config) (restore func()) {
	restore = func() {}
	if !wantsEgressPin(cfg) {
		return
	}
	name := findEgress(cfg)
	if name == "" {
		return
	}
	egressPin.mu.Lock()
	egressPin.name = name
	egressPin.mu.Unlock()
	cfg.General.Interface = name
	// The config keeps no pin, so a later apply does not store it again.
	return func() { cfg.General.Interface = "" }
}

// pinEgressNow covers a TUN turned on by a patch, with no apply to carry it.
func pinEgressNow(cfg *config.Config) {
	if !wantsEgressPin(cfg) {
		return
	}
	name := findEgress(cfg)
	if name == "" {
		return
	}
	egressPin.mu.Lock()
	egressPin.name = name
	egressPin.mu.Unlock()
	dialer.DefaultInterface.CompareAndSwap("", name)
}

func egressPinned() bool {
	egressPin.mu.Lock()
	defer egressPin.mu.Unlock()
	return egressPin.name != ""
}

// The TUN's finder follows network changes; a pin left behind would not.
func releaseEgress() {
	egressPin.mu.Lock()
	name := egressPin.name
	egressPin.name = ""
	egressPin.mu.Unlock()
	if name != "" {
		dialer.DefaultInterface.CompareAndSwap(name, "")
	}
}

// A connected UDP socket sends nothing; it only asks the routing table which
// local address would. Before the TUN's routes exist that is the physical one.
func physicalEgress(cfg *config.Config) string {
	for _, target := range []string{"8.8.8.8:53", "[2001:4860:4860::8888]:53"} {
		conn, err := net.Dial("udp", target)
		if err != nil {
			continue
		}
		local, ok := conn.LocalAddr().(*net.UDPAddr)
		_ = conn.Close()
		if !ok {
			continue
		}
		if name := interfaceOwning(local.AddrPort().Addr().Unmap(), cfg); name != "" {
			return name
		}
	}
	return ""
}

func interfaceOwning(addr netip.Addr, cfg *config.Config) string {
	tun := cfg.General.Tun
	for _, prefix := range append(append([]netip.Prefix{}, tun.Inet4Address...), tun.Inet6Address...) {
		if prefix.Contains(addr) {
			return ""
		}
	}
	interfaces, err := net.Interfaces()
	if err != nil {
		return ""
	}
	for _, ifc := range interfaces {
		if ifc.Name == tun.Device {
			continue
		}
		addrs, err := ifc.Addrs()
		if err != nil {
			continue
		}
		for _, a := range addrs {
			ipNet, ok := a.(*net.IPNet)
			if !ok {
				continue
			}
			if ip, ok := netip.AddrFromSlice(ipNet.IP); ok && ip.Unmap() == addr {
				return ifc.Name
			}
		}
	}
	return ""
}
