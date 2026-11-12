package core

import (
	"testing"

	"github.com/metacubex/mihomo/config"
)

func TestEveryGroupAndProviderTestsOnTheOneInterval(t *testing.T) {
	raw := config.DefaultRawConfig()
	raw.ProxyGroup = []map[string]any{
		{"name": "auto", "type": "url-test", "interval": 60},
		{"name": "pick", "type": "select"},
	}
	raw.ProxyProvider = map[string]map[string]any{
		"bare": {"type": "http"},
		"own": {"type": "http", "health-check": map[string]any{
			"enable": false, "interval": 3600, "url": "https://probe.test/204",
		}},
	}

	withTestInterval(raw)

	for _, group := range raw.ProxyGroup {
		if got := group["interval"]; got != testInterval {
			t.Errorf("group %v interval = %v, want %d", group["name"], got, testInterval)
		}
	}
	bare := raw.ProxyProvider["bare"]["health-check"].(map[string]any)
	if bare["enable"] != true || bare["interval"] != testInterval {
		t.Errorf("a provider without a health check got %v", bare)
	}
	own := raw.ProxyProvider["own"]["health-check"].(map[string]any)
	if own["enable"] != true || own["interval"] != testInterval {
		t.Errorf("a provider's own health check kept %v", own)
	}
	if own["url"] != "https://probe.test/204" {
		t.Errorf("a provider's own test url was replaced by %v", own["url"])
	}
}
