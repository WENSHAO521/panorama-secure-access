package core

import (
	"fmt"

	"github.com/metacubex/mihomo/adapter/outbound"
	"github.com/metacubex/mihomo/config"
	"github.com/metacubex/mihomo/tunnel"
)

// Unset, a hysteria2 handshake runs under the first request's context, so a
// short or cancelled probe aborts it for every request waiting on the session.
const hysteria2HandshakeTimeout = 10

var hysteria2HandshakeTimeoutExpr = fmt.Sprintf(
	`(select(.type == "hysteria2" and .handshake-timeout == null) | .handshake-timeout) = %d`,
	hysteria2HandshakeTimeout,
)

func withQuicDefaults(raw *config.RawConfig) {
	for _, mapping := range raw.Proxy {
		if mapping["type"] == "hysteria2" && !hasAnyKey(mapping, "handshake-timeout", "handshake_timeout") {
			mapping["handshake-timeout"] = hysteria2HandshakeTimeout
		}
	}
	for _, provider := range raw.ProxyProvider {
		override, ok := provider["override"].(map[string]any)
		if provider["override"] == nil {
			override, ok = map[string]any{}, true
		}
		if !ok {
			continue
		}
		var exprs []any
		switch existing := override["override-expr"].(type) {
		case nil:
		case []any:
			exprs = existing
		default:
			continue
		}
		override["override-expr"] = append(exprs, hysteria2HandshakeTimeoutExpr)
		provider["override"] = override
	}
}

func hasAnyKey(mapping map[string]any, keys ...string) bool {
	for _, key := range keys {
		if _, ok := mapping[key]; ok {
			return true
		}
	}
	return false
}

// Close drops only the session, which otherwise outlives its route until the QUIC idle timeout.
func resetQuicSessions() {
	safeGo("resetQuicSessions", closeQuicSessions)
}

func closeQuicSessions() {
	for _, proxy := range tunnel.AllProxies() {
		if hy2, ok := adapterAs[*outbound.Hysteria2](proxy); ok {
			_ = hy2.Close()
		}
	}
}
