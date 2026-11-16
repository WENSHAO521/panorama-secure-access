package core

import (
	"fmt"

		"github.com/metacubex/mihomo/config"
	"github.com/metacubex/mihomo/constant"
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

// WireGuard keeps one UDP socket, and Hysteria2 and TUIC one QUIC connection,
// for all their traffic; after a route change they stay on the old network.
func resetSharedOutbounds() {
	safeGo("resetSharedOutbounds", reopenSharedOutbounds)
}

type networkResetter interface{ ResetNetwork() }

// AllProxies keeps one proxy per name; providers may each hold one by that name.
func reopenSharedOutbounds() {
	reset := make(map[networkResetter]struct{})
	visit := func(proxy constant.Proxy) {
		outbound, ok := adapterAs[networkResetter](proxy)
		if !ok {
			return
		}
		if _, done := reset[outbound]; done {
			return
		}
		reset[outbound] = struct{}{}
		outbound.ResetNetwork()
	}
	for _, proxy := range tunnel.AllProxies() {
		visit(proxy)
	}
	for _, provider := range tunnel.ProvidersSnapshot() {
		for _, proxy := range provider.Proxies() {
			visit(proxy)
		}
	}
}
