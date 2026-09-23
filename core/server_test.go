//go:build !cgo

package main

import (
	"io"
	"net"
	"sync"
	"testing"
	"time"
)

// closeTrackingConn records whether the server closed the connection.
type closeTrackingConn struct {
	net.Conn
	mu     sync.Mutex
	closed bool
}

func (c *closeTrackingConn) Close() error {
	c.mu.Lock()
	c.closed = true
	c.mu.Unlock()
	return c.Conn.Close()
}

func (c *closeTrackingConn) isClosed() bool {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.closed
}

// Upstream FlClash (60f371a, v0.8.98) fixed the Core dying when Windows
// Modern Standby suspends the app: its writer put a deadline on each frame
// and closed the connection when a half-written frame timed out. This
// writer sets no deadline, so a write to a host that stopped reading just
// waits. This pins that property: a frame sent while the host isn't reading
// arrives intact once it reads again, and the connection stays open.
func TestSendWaitsForAHostThatStoppedReading(t *testing.T) {
	server, host := net.Pipe()
	defer host.Close()
	tracked := &closeTrackingConn{Conn: server}

	connMu.Lock()
	previous := conn
	conn = tracked
	connMu.Unlock()
	defer func() {
		connMu.Lock()
		conn = previous
		connMu.Unlock()
		_ = server.Close()
	}()

	// Larger than any pipe buffer would absorb in one go.
	payload := make([]byte, 256*1024)
	for i := range payload {
		payload[i] = byte('a' + i%26)
	}

	done := make(chan struct{})
	go func() {
		send(payload)
		close(done)
	}()

	// The host is "suspended": nothing reads for a while.
	select {
	case <-done:
		t.Fatal("send returned while the host wasn't reading; the frame can't have been delivered")
	case <-time.After(300 * time.Millisecond):
	}
	if tracked.isClosed() {
		t.Fatal("the connection was closed while the host was suspended")
	}

	// The host wakes and drains.
	frame, err := readFrame(host)
	if err != nil {
		t.Fatalf("reading the frame after the host woke: %v", err)
	}
	<-done
	if len(frame) != len(payload) || string(frame) != string(payload) {
		t.Fatalf("frame arrived damaged: got %d bytes, want %d", len(frame), len(payload))
	}
	if tracked.isClosed() {
		t.Fatal("the connection was closed after a delayed but successful write")
	}

	// And the stream is still in sync for the next frame.
	go send([]byte("{}"))
	next, err := readFrame(host)
	if err != nil || string(next) != "{}" {
		t.Fatalf("next frame = %q, %v; want {}", next, err)
	}
}

var _ io.ReadWriteCloser = (*closeTrackingConn)(nil)
