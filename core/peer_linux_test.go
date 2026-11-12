//go:build linux && !android

package core

import (
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"testing"
)

const testAppExecutable = "/usr/share/FlClash/FlClash"

func fakeHostProcess(t *testing.T, pid int, executable string, tracer int, environment ...string) string {
	t.Helper()
	root := t.TempDir()
	process := filepath.Join(root, strconv.Itoa(pid))
	if err := os.MkdirAll(process, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.Symlink(executable, filepath.Join(process, "exe")); err != nil {
		t.Fatal(err)
	}
	status := "Name:\tFlClash\nTracerPid:\t" + strconv.Itoa(tracer) + "\n"
	if err := os.WriteFile(filepath.Join(process, "status"), []byte(status), 0o644); err != nil {
		t.Fatal(err)
	}
	environ := strings.Join(environment, "\x00") + "\x00"
	if err := os.WriteFile(filepath.Join(process, "environ"), []byte(environ), 0o644); err != nil {
		t.Fatal(err)
	}
	return root
}

func TestVerifyHostProcessAcceptsThePackagedApp(t *testing.T) {
	root := fakeHostProcess(t, 7, testAppExecutable, 0, "HOME=/home/u", "LD_PRELOAD=")
	if err := verifyHostProcess(root, 7, testAppExecutable); err != nil {
		t.Fatal(err)
	}
	upgraded := fakeHostProcess(t, 8, testAppExecutable+" (deleted)", 0)
	if err := verifyHostProcess(upgraded, 8, testAppExecutable); err != nil {
		t.Fatal(err)
	}
}

func TestVerifyHostProcessRejectsAnotherProgramOfTheSameAccount(t *testing.T) {
	root := fakeHostProcess(t, 9, "/usr/bin/socat", 0)
	if err := verifyHostProcess(root, 9, testAppExecutable); err == nil {
		t.Fatal("a non-app host was accepted")
	}
}

func TestVerifyHostProcessRejectsATracedOrInjectedApp(t *testing.T) {
	traced := fakeHostProcess(t, 10, testAppExecutable, 31)
	if err := verifyHostProcess(traced, 10, testAppExecutable); err == nil {
		t.Fatal("a traced host was accepted")
	}
	for _, variable := range loaderInjectionVariables {
		injected := fakeHostProcess(t, 11, testAppExecutable, 0, variable+"=/tmp/evil.so")
		if err := verifyHostProcess(injected, 11, testAppExecutable); err == nil {
			t.Fatalf("a host started with %s was accepted", variable)
		}
	}
}

func TestVerifyHostProcessRejectsAMissingProcess(t *testing.T) {
	if err := verifyHostProcess(t.TempDir(), 12, testAppExecutable); err == nil {
		t.Fatal("a missing host was accepted")
	}
	if err := verifyHostProcess(t.TempDir(), 0, testAppExecutable); err == nil {
		t.Fatal("a host without a PID was accepted")
	}
}
