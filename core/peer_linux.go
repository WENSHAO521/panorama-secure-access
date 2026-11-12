//go:build linux && !android

package core

import (
	"bytes"
	"errors"
	"fmt"
	"net"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	"golang.org/x/sys/unix"
)

const appExecutableName = "FlClash"

var loaderInjectionVariables = []string{"LD_PRELOAD", "LD_AUDIT", "LD_LIBRARY_PATH"}

// The owner can replace the socket between the Helper's /start check and this
// dial, so an elevated Core checks the listener itself before serving it.
func verifyHost(conn net.Conn) error {
	if !isElevated() {
		return nil
	}
	unixConn, ok := conn.(*net.UnixConn)
	if !ok {
		return errors.New("an elevated Core only serves a Unix socket host")
	}
	raw, err := unixConn.SyscallConn()
	if err != nil {
		return err
	}
	var credentials *unix.Ucred
	var credentialsErr error
	if err := raw.Control(func(fd uintptr) {
		credentials, credentialsErr = unix.GetsockoptUcred(int(fd), unix.SOL_SOCKET, unix.SO_PEERCRED)
	}); err != nil {
		return err
	}
	if credentialsErr != nil {
		return credentialsErr
	}
	if int(credentials.Uid) != realUid {
		return fmt.Errorf("host runs as UID %d, not %d", credentials.Uid, realUid)
	}
	self, err := os.Executable()
	if err != nil {
		return err
	}
	return verifyHostProcess("/proc", int(credentials.Pid), filepath.Join(filepath.Dir(self), appExecutableName))
}

func verifyHostProcess(procRoot string, pid int, appExecutable string) error {
	if pid <= 0 {
		return errors.New("host has no process ID")
	}
	process := filepath.Join(procRoot, strconv.Itoa(pid))
	executable, err := os.Readlink(filepath.Join(process, "exe"))
	if err != nil {
		return err
	}
	executable = strings.TrimSuffix(executable, " (deleted)")
	if executable != appExecutable {
		return fmt.Errorf("host %d runs %s, not %s", pid, executable, appExecutable)
	}
	status, err := os.ReadFile(filepath.Join(process, "status"))
	if err != nil {
		return err
	}
	if tracer := tracerPid(string(status)); tracer != "0" {
		return fmt.Errorf("host %d is traced by %q", pid, tracer)
	}
	environment, err := os.ReadFile(filepath.Join(process, "environ"))
	if err != nil {
		return err
	}
	for _, entry := range bytes.Split(environment, []byte{0}) {
		name, value, found := bytes.Cut(entry, []byte{'='})
		if !found || len(value) == 0 {
			continue
		}
		for _, variable := range loaderInjectionVariables {
			if string(name) == variable {
				return fmt.Errorf("host %d was started with %s", pid, variable)
			}
		}
	}
	return nil
}

func tracerPid(status string) string {
	for _, line := range strings.Split(status, "\n") {
		if value, found := strings.CutPrefix(line, "TracerPid:"); found {
			return strings.TrimSpace(value)
		}
	}
	return ""
}
