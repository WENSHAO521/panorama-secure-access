package core

import (
	"sync"
	"time"

	"github.com/metacubex/mihomo/config"
	"github.com/metacubex/mihomo/constant/features"
)

// Windows takes seconds to bring up the TUN (eleven in a user's log); a check
// sent meanwhile is reset and outdated by the toggle, so the host asks again
// and the check spins. coreTunSettleAllowance on the host covers this wait.
const tunSettleLimit = 20 * time.Second

const directProxyName = "DIRECT"

var tunSettle struct {
	mu      sync.Mutex
	holders int
	done    chan struct{}
}

// A start applies the config and starts the listener side by side, and the
// host already sends its routed checks: hold them until the TUN is up, too.
var tunStart struct {
	mu    sync.Mutex
	done  chan struct{}
	timer *time.Timer
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

// holdForTunStart runs when a config with the TUN on lands before the listener
// starts; endTunStart lets the held checks go once the listener has started,
// stopped, or the limit passed without a start.
func holdForTunStart(cfg *config.Config) {
	if features.Android || cfg == nil || !cfg.General.Tun.Enable || isRunning.Load() {
		return
	}
	tunStart.mu.Lock()
	defer tunStart.mu.Unlock()
	if tunStart.done == nil {
		tunStart.done = make(chan struct{})
	}
	if tunStart.timer != nil {
		tunStart.timer.Stop()
	}
	tunStart.timer = time.AfterFunc(tunSettleLimit, endTunStart)
}

func endTunStart() {
	tunStart.mu.Lock()
	defer tunStart.mu.Unlock()
	if tunStart.timer != nil {
		tunStart.timer.Stop()
		tunStart.timer = nil
	}
	if tunStart.done != nil {
		close(tunStart.done)
		tunStart.done = nil
	}
}

// A direct check does not ride the TUN's routes, and runs while stopped too.
func awaitTunSettled(proxyName string) {
	tunSettle.mu.Lock()
	toggle := tunSettle.done
	tunSettle.mu.Unlock()
	var start chan struct{}
	if proxyName != directProxyName {
		tunStart.mu.Lock()
		start = tunStart.done
		tunStart.mu.Unlock()
	}
	if toggle == nil && start == nil {
		return
	}
	limit := time.NewTimer(tunSettleLimit)
	defer limit.Stop()
	if start != nil {
		select {
		case <-start:
		case <-limit.C:
			return
		}
		// The start's own toggle may have begun after this check looked.
		tunSettle.mu.Lock()
		toggle = tunSettle.done
		tunSettle.mu.Unlock()
	}
	if toggle != nil {
		select {
		case <-toggle:
		case <-limit.C:
		}
	}
}
