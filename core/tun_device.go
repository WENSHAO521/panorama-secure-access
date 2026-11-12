package core

import "runtime"

// defaultTunDevice replaces a configured name the OS cannot create: releases
// up to 3.5.x defaulted to the display name "Panorama Secure Access".
const defaultTunDevice = "PanoramaTun"

// Linux refuses an interface name longer than 15 bytes or holding whitespace,
// '/' or ':' (dev_valid_name), so TUNSETIFF fails with EINVAL and TUN never
// starts; wintun adapters with spaces fail on some Windows setups. macOS
// always gets a utun name from mihomo.
func sanitizeTunDevice(name string) string {
	if runtime.GOOS == "darwin" || name == "" || validTunDevice(name) {
		return name
	}
	return defaultTunDevice
}

func validTunDevice(name string) bool {
	if len(name) > 15 || name == "." || name == ".." {
		return false
	}
	for _, r := range name {
		if r <= ' ' || r > '~' || r == '/' || r == ':' {
			return false
		}
	}
	return true
}
