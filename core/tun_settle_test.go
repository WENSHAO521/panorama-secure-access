package core

import (
	"testing"
	"time"

	"github.com/metacubex/mihomo/config"
)

func TestChecksWaitForTheDesktopTunToggle(t *testing.T) {
	wasRunning, wasTun := isRunning.Load(), tunEnabled.Load()
	t.Cleanup(func() {
		isRunning.Store(wasRunning)
		tunEnabled.Store(wasTun)
	})
	isRunning.Store(true)
	tunEnabled.Store(false)
	cfg := &config.Config{General: &config.General{}}
	cfg.General.Tun.Enable = true

	release := beginTunSettle(cfg)
	inner := beginTunSettle(cfg)
	waited := make(chan struct{})
	go func() {
		awaitTunSettled("")
		close(waited)
	}()
	inner()
	select {
	case <-waited:
		t.Fatal("a check went out while the TUN was still coming up")
	case <-time.After(50 * time.Millisecond):
	}
	release()
	release()
	select {
	case <-waited:
	case <-time.After(time.Second):
		t.Fatal("the check kept waiting after the toggle landed")
	}
}

func TestChecksRunAtOnceWithoutATunToggle(t *testing.T) {
	wasRunning, wasTun := isRunning.Load(), tunEnabled.Load()
	t.Cleanup(func() {
		isRunning.Store(wasRunning)
		tunEnabled.Store(wasTun)
	})
	isRunning.Store(true)
	tunEnabled.Store(true)
	cfg := &config.Config{General: &config.General{}}
	cfg.General.Tun.Enable = true

	defer beginTunSettle(cfg)()
	done := make(chan struct{})
	go func() {
		awaitTunSettled("")
		close(done)
	}()
	select {
	case <-done:
	case <-time.After(time.Second):
		t.Fatal("a check waited with no TUN toggle under way")
	}
}

func TestRoutedChecksWaitForTheTunStart(t *testing.T) {
	wasRunning, wasTun := isRunning.Load(), tunEnabled.Load()
	t.Cleanup(func() {
		isRunning.Store(wasRunning)
		tunEnabled.Store(wasTun)
		endTunStart()
	})
	isRunning.Store(false)
	tunEnabled.Store(false)
	cfg := &config.Config{General: &config.General{}}
	cfg.General.Tun.Enable = true

	holdForTunStart(cfg)
	direct := make(chan struct{})
	go func() {
		awaitTunSettled(directProxyName)
		close(direct)
	}()
	select {
	case <-direct:
	case <-time.After(time.Second):
		t.Fatal("a direct check waited for the TUN start")
	}

	routed := make(chan struct{})
	go func() {
		awaitTunSettled("")
		close(routed)
	}()
	select {
	case <-routed:
		t.Fatal("a routed check went out before the listener started")
	case <-time.After(50 * time.Millisecond):
	}
	endTunStart()
	select {
	case <-routed:
	case <-time.After(time.Second):
		t.Fatal("the check kept waiting after the listener started")
	}
}

func TestNoStartHoldWithoutTheTun(t *testing.T) {
	wasRunning := isRunning.Load()
	t.Cleanup(func() {
		isRunning.Store(wasRunning)
		endTunStart()
	})
	isRunning.Store(false)
	cfg := &config.Config{General: &config.General{}}

	holdForTunStart(cfg)
	done := make(chan struct{})
	go func() {
		awaitTunSettled("")
		close(done)
	}()
	select {
	case <-done:
	case <-time.After(time.Second):
		t.Fatal("a check waited for a start with the TUN off")
	}
}

func TestChecksWaitForTheResetAfterTheTunCameUp(t *testing.T) {
	was := tunAftershockDelay
	tunAftershockDelay = 50 * time.Millisecond
	t.Cleanup(func() { tunAftershockDelay = was })

	reset := make(chan struct{})
	scheduleTunAftershock(func() { close(reset) })
	checked := make(chan struct{})
	go func() {
		awaitTunSettled("")
		close(checked)
	}()
	select {
	case <-checked:
		t.Fatal("a check went out before the reset after the TUN came up")
	case <-reset:
	}
	select {
	case <-checked:
	case <-time.After(time.Second):
		t.Fatal("the check kept waiting after the reset")
	}
}
