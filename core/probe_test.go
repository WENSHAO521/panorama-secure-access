package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"net/url"
	"testing"
	"time"

	"github.com/metacubex/mihomo/adapter"
	"github.com/metacubex/mihomo/adapter/outbound"
	C "github.com/metacubex/mihomo/constant"
	P "github.com/metacubex/mihomo/constant/provider"
	RC "github.com/metacubex/mihomo/rules/common"
	"github.com/metacubex/mihomo/tunnel"
)

// Every rule-routed connection is rejected, so a request that succeeds
// through a probe listener can only have gone via the pinned proxy.
func setupRejectAllTunnel(t *testing.T) {
	t.Helper()
	tunnel.UpdateProxies(map[string]C.Proxy{
		"DIRECT": adapter.NewProxy(outbound.NewDirect()),
		"REJECT": adapter.NewProxy(outbound.NewReject()),
	}, map[string]P.ProxyProvider{})
	tunnel.UpdateRules([]C.Rule{RC.NewMatch("REJECT")}, nil, nil)
	tunnel.SetMode(tunnel.Rule)
	tunnel.OnRunning()
	t.Cleanup(stopProbeListener)
}

func startTestServer(t *testing.T) *httptest.Server {
	t.Helper()
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		_, _ = io.WriteString(w, "reached")
	}))
	t.Cleanup(server.Close)
	return server
}

func getViaProxy(port int, target string) (string, error) {
	proxyURL, _ := url.Parse(fmt.Sprintf("http://127.0.0.1:%d", port))
	client := &http.Client{
		Transport: &http.Transport{Proxy: http.ProxyURL(proxyURL)},
		Timeout:   5 * time.Second,
	}
	response, err := client.Get(target)
	if err != nil {
		return "", err
	}
	defer response.Body.Close()
	body, err := io.ReadAll(response.Body)
	if err != nil {
		return "", err
	}
	if response.StatusCode != http.StatusOK {
		return "", fmt.Errorf("status %d", response.StatusCode)
	}
	return string(body), nil
}

func TestProbeListenerRoutesThroughPinnedProxyNotRules(t *testing.T) {
	setupRejectAllTunnel(t)
	server := startTestServer(t)

	port, err := startProbeListener("DIRECT")
	if err != nil {
		t.Fatalf("start: %v", err)
	}
	body, err := getViaProxy(port, server.URL)
	if err != nil {
		t.Fatalf("request through probe pinned to DIRECT failed: %v", err)
	}
	if body != "reached" {
		t.Fatalf("unexpected body %q", body)
	}
}

func TestProbeListenerPinnedToRejectIsRejected(t *testing.T) {
	setupRejectAllTunnel(t)
	server := startTestServer(t)

	port, err := startProbeListener("REJECT")
	if err != nil {
		t.Fatalf("start: %v", err)
	}
	if _, err := getViaProxy(port, server.URL); err == nil {
		t.Fatal("request through probe pinned to REJECT succeeded")
	}
}

func TestProbeListenerListensOnLoopbackOnly(t *testing.T) {
	setupRejectAllTunnel(t)

	if _, err := startProbeListener("DIRECT"); err != nil {
		t.Fatalf("start: %v", err)
	}
	host, _, err := net.SplitHostPort(probeListener.Address())
	if err != nil || host != "127.0.0.1" {
		t.Fatalf("listening on %q, want 127.0.0.1", probeListener.Address())
	}
}

func TestProbeListenerUnknownProxy(t *testing.T) {
	setupRejectAllTunnel(t)

	var result probeListenerResult
	if err := json.Unmarshal([]byte(handleStartProbeListener(`{"proxy":"JP-01"}`)), &result); err != nil {
		t.Fatal(err)
	}
	if result.Port != 0 || result.Error == "" {
		t.Fatalf("want an error for an unknown proxy, got %+v", result)
	}
}

func TestProbeListenerMalformedParams(t *testing.T) {
	var result probeListenerResult
	if err := json.Unmarshal([]byte(handleStartProbeListener(`not json`)), &result); err != nil {
		t.Fatal(err)
	}
	if result.Error == "" {
		t.Fatal("want an error for malformed params")
	}
}

func TestStopProbeListenerClosesThePort(t *testing.T) {
	setupRejectAllTunnel(t)

	port, err := startProbeListener("DIRECT")
	if err != nil {
		t.Fatalf("start: %v", err)
	}
	handleStopProbeListener()
	if probeListener != nil {
		t.Fatal("probe listener still set after stop")
	}
	conn, err := net.DialTimeout("tcp", fmt.Sprintf("127.0.0.1:%d", port), time.Second)
	if err == nil {
		conn.Close()
		t.Fatal("port still accepting connections after stop")
	}
}

func TestStartingAgainReplacesThePreviousProbe(t *testing.T) {
	setupRejectAllTunnel(t)

	first, err := startProbeListener("DIRECT")
	if err != nil {
		t.Fatalf("first start: %v", err)
	}
	if _, err := startProbeListener("REJECT"); err != nil {
		t.Fatalf("second start: %v", err)
	}
	conn, err := net.DialTimeout("tcp", fmt.Sprintf("127.0.0.1:%d", first), time.Second)
	if err == nil {
		conn.Close()
		t.Fatal("first probe port still open after starting another")
	}
}
