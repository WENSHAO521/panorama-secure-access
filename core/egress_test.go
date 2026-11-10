package core

import (
	"testing"

	"github.com/metacubex/mihomo/component/dialer"
	"github.com/metacubex/mihomo/config"
)

func egressTestConfig() *config.Config {
	cfg := &config.Config{General: &config.General{}}
	cfg.General.Tun.Enable = true
	cfg.General.Tun.AutoDetectInterface = true
	return cfg
}

func stubEgress(t *testing.T, name string) {
	wasPlatform, wasFind := egressPinPlatform, findEgress
	egressPinPlatform = true
	findEgress = func(*config.Config) string { return name }
	t.Cleanup(func() {
		egressPinPlatform, findEgress = wasPlatform, wasFind
		releaseEgress()
		dialer.DefaultInterface.Store("")
	})
}

func TestTheFirstApplyBindsThePhysicalInterfaceUntilTheTun(t *testing.T) {
	stubEgress(t, "Wi-Fi")
	cfg := egressTestConfig()

	restore := pinEgress(cfg)
	if cfg.General.Interface != "Wi-Fi" {
		t.Fatalf("apply carries interface %q, want Wi-Fi", cfg.General.Interface)
	}
	dialer.DefaultInterface.Store(cfg.General.Interface) // what the executor does
	restore()
	if cfg.General.Interface != "" {
		t.Fatal("the pin stayed in the config, so a later apply would store it again")
	}
	if !egressPinned() {
		t.Fatal("the pin was not remembered for its release")
	}

	releaseEgress()
	if got := dialer.DefaultInterface.Load(); got != "" {
		t.Fatalf("interface %q left bound after the TUN came up", got)
	}
}

func TestAnExplicitInterfaceIsLeftAlone(t *testing.T) {
	stubEgress(t, "Wi-Fi")
	cfg := egressTestConfig()
	cfg.General.Interface = "Ethernet"

	pinEgress(cfg)()
	if cfg.General.Interface != "Ethernet" || egressPinned() {
		t.Fatal("the user's interface-name was overridden")
	}

	dialer.DefaultInterface.Store("Ethernet")
	releaseEgress()
	if dialer.DefaultInterface.Load() != "Ethernet" {
		t.Fatal("the release cleared the user's interface-name")
	}
}

func TestNoPinWithoutTheTunOrAutoDetect(t *testing.T) {
	stubEgress(t, "Wi-Fi")
	off := egressTestConfig()
	off.General.Tun.Enable = false
	manual := egressTestConfig()
	manual.General.Tun.AutoDetectInterface = false

	for _, cfg := range []*config.Config{off, manual} {
		pinEgress(cfg)()
		if cfg.General.Interface != "" || egressPinned() {
			t.Fatal("pinned an interface the TUN would not have bound")
		}
	}
}

func TestATunTurnedOnByAPatchIsPinnedToo(t *testing.T) {
	stubEgress(t, "en0")
	pinEgressNow(egressTestConfig())
	if dialer.DefaultInterface.Load() != "en0" {
		t.Fatal("a TUN turned on at runtime came up unpinned")
	}
	releaseEgress()
	if dialer.DefaultInterface.Load() != "" {
		t.Fatal("the runtime pin outlived the TUN start")
	}
}

func TestAStartReplacesAPinLeftByAnApplyWhileStopped(t *testing.T) {
	stubEgress(t, "Wi-Fi")
	cfg := egressTestConfig()
	restore := pinEgress(cfg)
	dialer.DefaultInterface.Store(cfg.General.Interface)
	restore()

	findEgress = func(*config.Config) string { return "Ethernet" }
	pinEgressNow(cfg)
	if got := dialer.DefaultInterface.Load(); got != "Ethernet" {
		t.Fatalf("the start kept the stale pin %q", got)
	}
	releaseEgress()
	if got := dialer.DefaultInterface.Load(); got != "" {
		t.Fatalf("interface %q left bound after the TUN came up", got)
	}
}
