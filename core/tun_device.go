package core

import "runtime"

const defaultTunDevice = "PanoramaTun"

// Linux's dev_valid_name rejects the old default "Panorama Secure Access".
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
