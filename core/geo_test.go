package core

import (
	"context"
	"errors"
	"os"
	"path/filepath"
	"reflect"
	"testing"
	"time"
)

func TestDueGeoTypesJudgesEachFileByItsOwnAge(t *testing.T) {
	now := time.Date(2026, 11, 14, 12, 0, 0, 0, time.UTC)
	modTimes := map[string]time.Time{
		"GEOIP":   now.Add(-time.Hour),
		"GEOSITE": now.Add(-25 * time.Hour),
		"MMDB":    now.Add(-24 * time.Hour),
		"ASN":     {},
	}

	got := dueGeoTypes(now, 24*time.Hour, modTimes, map[string]time.Time{})

	want := []string{"ASN", "GEOSITE", "MMDB"}
	if !reflect.DeepEqual(got, want) {
		t.Errorf("due = %v, want %v: a fresh GeoIP must not hide the stale files", got, want)
	}
}

func TestDueGeoTypesWaitsBeforeRetryingAFailure(t *testing.T) {
	now := time.Date(2026, 11, 14, 12, 0, 0, 0, time.UTC)
	modTimes := map[string]time.Time{"GEOSITE": now.Add(-48 * time.Hour)}

	recent := map[string]time.Time{"GEOSITE": now.Add(-geoRetryDelay / 2)}
	if got := dueGeoTypes(now, 24*time.Hour, modTimes, recent); len(got) != 0 {
		t.Errorf("due = %v right after a failure, want a pause", got)
	}

	old := map[string]time.Time{"GEOSITE": now.Add(-geoRetryDelay)}
	if got := dueGeoTypes(now, 24*time.Hour, modTimes, old); !reflect.DeepEqual(got, []string{"GEOSITE"}) {
		t.Errorf("due = %v once the retry delay passed, want GEOSITE retried", got)
	}
}

func stubGeoResources(t *testing.T, ages map[string]time.Duration, fail map[string]bool) *[]string {
	t.Helper()
	dir := t.TempDir()
	var updated []string
	previous := geoResources
	stubs := make(map[string]geoResource, len(ages))
	for geoType, age := range ages {
		path := filepath.Join(dir, geoType)
		if age >= 0 {
			if err := os.WriteFile(path, []byte("x"), 0o600); err != nil {
				t.Fatal(err)
			}
			modTime := time.Now().Add(-age)
			if err := os.Chtimes(path, modTime, modTime); err != nil {
				t.Fatal(err)
			}
		}
		stubs[geoType] = geoResource{
			path: func() string { return path },
			update: func() error {
				updated = append(updated, geoType)
				if fail[geoType] {
					return errors.New("download failed")
				}
				return nil
			},
		}
	}
	geoResources = stubs
	t.Cleanup(func() { geoResources = previous })
	return &updated
}

func TestUpdateDueGeoResourcesUpdatesStaleAndMissingFiles(t *testing.T) {
	updated := stubGeoResources(t, map[string]time.Duration{
		"GEOIP":   time.Hour,
		"GEOSITE": 30 * time.Hour,
		"MMDB":    -1,
	}, nil)

	updateDueGeoResources(context.Background(), 24*time.Hour, map[string]time.Time{})

	if want := []string{"GEOSITE", "MMDB"}; !reflect.DeepEqual(*updated, want) {
		t.Errorf("updated = %v, want %v", *updated, want)
	}
}

func TestUpdateDueGeoResourcesKeepsGoingAfterAFailure(t *testing.T) {
	updated := stubGeoResources(t, map[string]time.Duration{
		"ASN":     30 * time.Hour,
		"GEOSITE": 30 * time.Hour,
	}, map[string]bool{"ASN": true})
	failedAt := map[string]time.Time{}

	updateDueGeoResources(context.Background(), 24*time.Hour, failedAt)

	if want := []string{"ASN", "GEOSITE"}; !reflect.DeepEqual(*updated, want) {
		t.Errorf("updated = %v, want %v", *updated, want)
	}
	if _, ok := failedAt["ASN"]; !ok {
		t.Error("the failed ASN download was not recorded for a retry")
	}
	if _, ok := failedAt["GEOSITE"]; ok {
		t.Error("GEOSITE succeeded but was recorded as failed")
	}
	if !claimGeoUpdate("ASN") {
		t.Fatal("the failed update kept its claim")
	}
	releaseGeoUpdate("ASN")
}

func TestUpdateDueGeoResourcesLeavesAManualUpdateAlone(t *testing.T) {
	updated := stubGeoResources(t, map[string]time.Duration{"GEOSITE": 30 * time.Hour}, nil)
	if !claimGeoUpdate("GEOSITE") {
		t.Fatal("could not take the manual claim")
	}
	t.Cleanup(func() { releaseGeoUpdate("GEOSITE") })

	updateDueGeoResources(context.Background(), 24*time.Hour, map[string]time.Time{})

	if len(*updated) != 0 {
		t.Errorf("updated = %v while a manual update held the file", *updated)
	}
}
