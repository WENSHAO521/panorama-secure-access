package core

import (
	"sync"
	"time"

	"github.com/metacubex/mihomo/config"
	"github.com/metacubex/mihomo/constant/features"
)

// Windows takes seconds to bring up the TUN; a check sent meanwhile is reset
// and outdated by the toggle, so the host asks again and the check spins.
const tunSettleLimit = 10 * time.Second

var tunSettle struct {
	mu      sync.Mutex
	holders int
	done    chan struct{}
}

func tunWillToggle(cfg *config.Config) bool {
	return !features.Android && cfg != nil && isRunning.Load() &&
		cfg.General.Tun.Enable != tunEnabled.Load()
}

func beginTunSettle(cfg *config.Config) func() {
	if !tunWillToggle(cfg) {
		return func() {}
	}
	tunSettle.mu.Lock()
	if tunSettle.holders == 0 {
		tunSettle.done = make(chan struct{})
	}
	tunSettle.holders++
	tunSettle.mu.Unlock()
	var once sync.Once
	return func() {
		once.Do(func() {
			tunSettle.mu.Lock()
			defer tunSettle.mu.Unlock()
			tunSettle.holders--
			if tunSettle.holders == 0 {
				close(tunSettle.done)
				tunSettle.done = nil
			}
		})
	}
}

func awaitTunSettled() {
	tunSettle.mu.Lock()
	done := tunSettle.done
	tunSettle.mu.Unlock()
	if done == nil {
		return
	}
	select {
	case <-done:
	case <-time.After(tunSettleLimit):
	}
}
