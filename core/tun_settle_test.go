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
		awaitTunSettled()
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
		awaitTunSettled()
		close(done)
	}()
	select {
	case <-done:
	case <-time.After(time.Second):
		t.Fatal("a check waited with no TUN toggle under way")
	}
}
