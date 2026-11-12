//go:build !linux || android

package core

import "net"

func verifyHost(net.Conn) error {
	return nil
}
