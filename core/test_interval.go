package core

import "github.com/metacubex/mihomo/config"

// Overrides whatever a profile or its script sets for groups and providers.
const testInterval = 300

func withTestInterval(raw *config.RawConfig) {
	for _, group := range raw.ProxyGroup {
		group["interval"] = testInterval
	}
	for _, provider := range raw.ProxyProvider {
		check, ok := provider["health-check"].(map[string]any)
		if !ok {
			check = map[string]any{}
		}
		check["enable"] = true
		check["interval"] = testInterval
		provider["health-check"] = check
	}
}
