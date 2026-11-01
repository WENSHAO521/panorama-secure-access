package core

import (
	"testing"

	"github.com/metacubex/mihomo/adapter/provider"
	"github.com/metacubex/mihomo/config"
)

func TestWithQuicDefaultsSetsTheHysteria2HandshakeTimeout(t *testing.T) {
	raw := config.DefaultRawConfig()
	raw.Proxy = []map[string]any{
		{"name": "a", "type": "hysteria2"},
		{"name": "b", "type": "hysteria2", "handshake-timeout": 3},
		{"name": "c", "type": "vless"},
	}

	withQuicDefaults(raw)

	if got := raw.Proxy[0]["handshake-timeout"]; got != hysteria2HandshakeTimeout {
		t.Errorf("unset handshake-timeout = %v, want %d", got, hysteria2HandshakeTimeout)
	}
	if got := raw.Proxy[1]["handshake-timeout"]; got != 3 {
		t.Errorf("explicit handshake-timeout = %v, want the profile's 3 kept", got)
	}
	if _, ok := raw.Proxy[2]["handshake-timeout"]; ok {
		t.Error("a vless proxy was given a handshake-timeout")
	}
}

func TestWithQuicDefaultsReachesProviderProxies(t *testing.T) {
	raw := config.DefaultRawConfig()
	raw.ProxyProvider = map[string]map[string]any{
		"bare":   {"type": "http"},
		"listed": {"type": "http", "override": map[string]any{"override-expr": []any{`.udp = true`}}},
	}

	withQuicDefaults(raw)

	listed := raw.ProxyProvider["listed"]["override"].(map[string]any)["override-expr"].([]any)
	if len(listed) != 2 || listed[0] != `.udp = true` {
		t.Errorf("override-expr = %v, want the profile's expression kept ahead of the default", listed)
	}
	exprs := raw.ProxyProvider["bare"]["override"].(map[string]any)["override-expr"].([]any)
	expr, err := provider.NewOverrideExpr(exprs[0].(string))
	if err != nil {
		t.Fatalf("default override-expr does not parse: %v", err)
	}
	for _, tc := range []struct {
		mapping map[string]any
		want    any
	}{
		{map[string]any{"type": "hysteria2"}, hysteria2HandshakeTimeout},
		{map[string]any{"type": "hysteria2", "handshake-timeout": 3}, 3},
		{map[string]any{"type": "vless"}, nil},
	} {
		if err := expr.Apply(tc.mapping); err != nil {
			t.Fatalf("apply: %v", err)
		}
		if got := tc.mapping["handshake-timeout"]; got != tc.want {
			t.Errorf("%v: handshake-timeout = %v, want %v", tc.mapping["type"], got, tc.want)
		}
	}
}
