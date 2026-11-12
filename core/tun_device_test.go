package core

import (
	"runtime"
	"testing"
)

func TestSanitizeTunDeviceReplacesNamesTheKernelRejects(t *testing.T) {
	if runtime.GOOS == "darwin" {
		t.Skip("mihomo picks a utun name on macOS")
	}
	for name, want := range map[string]string{
		"":                       "",
		"FlClash":                "FlClash",
		"PanoramaTun":            "PanoramaTun",
		"tun0":                   "tun0",
		"Panorama Secure Access": defaultTunDevice,
		"sixteen-bytes-xx":       defaultTunDevice,
		"a/b":                    defaultTunDevice,
		"a:b":                    defaultTunDevice,
		"隧道":                     defaultTunDevice,
	} {
		if got := sanitizeTunDevice(name); got != want {
			t.Errorf("sanitizeTunDevice(%q) = %q, want %q", name, got, want)
		}
	}
}
