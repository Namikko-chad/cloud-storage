package backend

import (
	"fmt"
	"maps"
	"time"

	"cloudsync/core/vault"
)

// Google Drive limits requests per OAuth app (project), not per account.
// Drive storages added without an own client_id all use rclone's built-in
// app, so their requests count against one quota (shared with every rclone
// user). rclone paces each storage on its own, so N such storages would send
// N times the rate of one. driveMinSleep and driveBurst are rclone's
// defaults for one storage; SharePacing splits them between the storages.
const (
	driveMinSleep = 100 * time.Millisecond
	driveBurst    = 100
)

// usesSharedApp reports whether b is a Drive storage on rclone's built-in
// OAuth app. A service account belongs to its own project.
func usesSharedApp(b vault.Backend) bool {
	p := b.Params
	return b.Type == "drive" && p["client_id"] == "" &&
		p["service_account_file"] == "" && p["service_account_credentials"] == ""
}

// SharePacing returns b ready to open among all (the storages of the vault;
// b may be one of them or a new one). A Drive storage on rclone's built-in
// app gets 1/N of the request rate of one storage, N being the number of
// such storages, so together they send no more than one would. Pacing set
// in b's own params is kept. Other storages are returned unchanged.
func SharePacing(b vault.Backend, all []vault.Backend) vault.Backend {
	if !usesSharedApp(b) {
		return b
	}
	n := 0
	self := false
	for _, o := range all {
		if usesSharedApp(o) {
			n++
		}
		self = self || o.ID == b.ID
	}
	if !self {
		n++
	}
	if n <= 1 {
		return b
	}
	params := maps.Clone(b.Params)
	if params == nil {
		params = map[string]string{}
	}
	if params["pacer_min_sleep"] == "" {
		params["pacer_min_sleep"] = fmt.Sprintf("%dms", (driveMinSleep * time.Duration(n)).Milliseconds())
	}
	if params["pacer_burst"] == "" {
		params["pacer_burst"] = fmt.Sprint(max(driveBurst/n, 1))
	}
	b.Params = params
	return b
}
