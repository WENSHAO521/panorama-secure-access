package core

import (
	"context"
	"fmt"
	"os"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/metacubex/mihomo/component/geodata"
	"github.com/metacubex/mihomo/component/updater"
	C "github.com/metacubex/mihomo/constant"
	"github.com/metacubex/mihomo/log"
)

type geoResource struct {
	update func() error
	url    func() string
	setUrl func(string)
	path   func() string
}

var geoResources = map[string]geoResource{
	"MMDB":    {update: updater.UpdateMMDB, url: geodata.MmdbUrl, setUrl: geodata.SetMmdbUrl, path: C.Path.MMDB},
	"ASN":     {update: updater.UpdateASN, url: geodata.ASNUrl, setUrl: geodata.SetASNUrl, path: C.Path.ASN},
	"GEOIP":   {update: updater.UpdateGeoIp, url: geodata.GeoIpUrl, setUrl: geodata.SetGeoIpUrl, path: C.Path.GeoIP},
	"GEOSITE": {update: updater.UpdateGeoSite, url: geodata.GeoSiteUrl, setUrl: geodata.SetGeoSiteUrl, path: C.Path.GeoSite},
}

// mihomo's updaters read these links without a lock, so an unchanged one is never rewritten.
func setGeoResourceUrl(geoType string, link string) {
	resource, exist := geoResources[strings.ToUpper(geoType)]
	if !exist {
		log.Warnln("geox-url: unknown geo resource %q", geoType)
		return
	}
	if link != "" && link != resource.url() {
		resource.setUrl(link)
	}
}

func claimGeoUpdate(geoType string) bool {
	return claimUpdate(geoUpdateScope + geoType)
}

func releaseGeoUpdate(geoType string) {
	releaseUpdate(geoUpdateScope + geoType)
}

func handleUpdateGeoData(params GeoUpdateParams) error {
	geoType := params.Type
	resource, exist := geoResources[geoType]
	if !exist {
		logError("updateGeoData: unknown geo resource %q", geoType)
		return fmt.Errorf("unknown geo resource: %s", geoType)
	}
	if !claimGeoUpdate(geoType) {
		return fmt.Errorf("geo update already in progress: %s", geoType)
	}
	safeGo("updateGeoData("+geoType+")", func() {
		defer releaseGeoUpdate(geoType)
		if err := resource.update(); err != nil {
			logError("updateGeoData(%s) error: %v", geoType, err)
		}
	})
	return nil
}

func onGeoUpdate(geoType string, updating bool, skipped bool, updateErr error) {
	if updating {
		claimUpdateAs(geoUpdateScope+geoType, true)
	} else {
		releaseHookUpdate(geoUpdateScope + geoType)
		scheduleReclaimOwnership()
		if !skipped && updateErr == nil {
			changeRoute(routeMoved)
		}
	}
	status := GeoUpdateStatus{Type: geoType, Updating: updating, Skipped: skipped}
	if updateErr != nil {
		status.Error = updateErr.Error()
	}
	sendMessage(GeoUpdateMessage, status)
}

var (
	registerGeoUpdater = startGeoScheduler
	stopGeoUpdater     = stopGeoScheduler
)

func syncGeoUpdater(autoUpdate *bool, interval *int) {
	changed := false
	if autoUpdate != nil && *autoUpdate != updater.GeoAutoUpdate() {
		updater.SetGeoAutoUpdate(*autoUpdate)
		changed = true
	}
	if interval != nil && *interval != updater.GeoUpdateInterval() {
		updater.SetGeoUpdateInterval(*interval)
		changed = true
	}
	if changed {
		reconcileGeoUpdater()
	}
}

func reconcileGeoUpdater() {
	if updater.GeoAutoUpdate() {
		registerGeoUpdater()
		return
	}
	stopGeoUpdater()
}

// Not mihomo's updater: it dates every file by the first one that exists, its
// ticker stops while a device sleeps and restarts on every profile apply, and
// one failed download ends it for good.
const (
	geoStartDelay  = 30 * time.Second
	geoCheckPeriod = 15 * time.Minute
	geoRetryDelay  = 30 * time.Minute
)

var geoScheduler struct {
	sync.Mutex
	cancel context.CancelFunc
}

func startGeoScheduler() {
	geoScheduler.Lock()
	defer geoScheduler.Unlock()
	stopGeoSchedulerLocked()
	interval := time.Duration(updater.GeoUpdateInterval()) * time.Hour
	if interval <= 0 {
		log.Warnln("[GEO] invalid update interval: %d", updater.GeoUpdateInterval())
		return
	}
	ctx, cancel := context.WithCancel(context.Background())
	geoScheduler.cancel = cancel
	safeGo("geoScheduler", func() { runGeoScheduler(ctx, interval) })
}

func stopGeoScheduler() {
	geoScheduler.Lock()
	defer geoScheduler.Unlock()
	stopGeoSchedulerLocked()
}

func stopGeoSchedulerLocked() {
	if geoScheduler.cancel != nil {
		geoScheduler.cancel()
		geoScheduler.cancel = nil
	}
}

func runGeoScheduler(ctx context.Context, interval time.Duration) {
	failedAt := map[string]time.Time{}
	timer := time.NewTimer(geoStartDelay)
	defer timer.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-timer.C:
		}
		updateDueGeoResources(ctx, interval, failedAt)
		timer.Reset(geoCheckPeriod)
	}
}

func updateDueGeoResources(ctx context.Context, interval time.Duration, failedAt map[string]time.Time) {
	now := time.Now().Round(0)
	for _, geoType := range dueGeoTypes(now, interval, geoModTimes(), failedAt) {
		if ctx.Err() != nil {
			return
		}
		if !claimGeoUpdate(geoType) {
			continue
		}
		err := geoResources[geoType].update()
		releaseGeoUpdate(geoType)
		if err != nil {
			failedAt[geoType] = time.Now().Round(0)
			log.Warnln("[GEO] auto update %s failed, retrying in %v: %v", geoType, geoRetryDelay, err)
			continue
		}
		delete(failedAt, geoType)
	}
}

// A missing file keeps the zero time, which is always due.
func geoModTimes() map[string]time.Time {
	modTimes := make(map[string]time.Time, len(geoResources))
	for geoType, resource := range geoResources {
		var modTime time.Time
		if info, err := os.Stat(resource.path()); err == nil {
			modTime = info.ModTime()
		}
		modTimes[geoType] = modTime
	}
	return modTimes
}

// mihomo rewrites a file it downloads, and touches one whose hash came back
// unchanged, so the modification time is when the file was last checked.
func dueGeoTypes(
	now time.Time,
	interval time.Duration,
	modTimes map[string]time.Time,
	failedAt map[string]time.Time,
) []string {
	due := make([]string, 0, len(modTimes))
	for geoType, modTime := range modTimes {
		if failed, ok := failedAt[geoType]; ok && now.Sub(failed) < geoRetryDelay {
			continue
		}
		if now.Sub(modTime) >= interval {
			due = append(due, geoType)
		}
	}
	sort.Strings(due)
	return due
}
