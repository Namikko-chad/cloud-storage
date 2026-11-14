package backend

import (
	"testing"

	"cloudsync/core/vault"
)

func TestSharePacing(t *testing.T) {
	d1 := vault.Backend{ID: "d1", Type: "drive", Params: map[string]string{"token": "x"}}
	d2 := vault.Backend{ID: "d2", Type: "drive"}
	own := vault.Backend{ID: "d3", Type: "drive", Params: map[string]string{"client_id": "mine"}}
	sa := vault.Backend{ID: "d4", Type: "drive", Params: map[string]string{"service_account_file": "/k.json"}}
	mega := vault.Backend{ID: "m", Type: "mega"}
	all := []vault.Backend{d1, d2, own, sa, mega}

	got := SharePacing(d1, all)
	if got.Params["pacer_min_sleep"] != "200ms" || got.Params["pacer_burst"] != "50" || got.Params["token"] != "x" {
		t.Fatalf("d1 params: %v", got.Params)
	}
	if _, ok := d1.Params["pacer_min_sleep"]; ok {
		t.Fatal("vault params changed")
	}
	// A storage being added counts too.
	d5 := vault.Backend{ID: "d5", Type: "drive"}
	if got := SharePacing(d5, all); got.Params["pacer_min_sleep"] != "300ms" || got.Params["pacer_burst"] != "33" {
		t.Fatalf("new storage params: %v", got.Params)
	}
	// Alone on the shared app: rclone's defaults.
	if got := SharePacing(d1, []vault.Backend{d1, own}); got.Params["pacer_min_sleep"] != "" {
		t.Fatalf("single storage paced: %v", got.Params)
	}
	for _, b := range []vault.Backend{own, sa, mega} {
		if got := SharePacing(b, all); got.Params["pacer_min_sleep"] != "" {
			t.Fatalf("%s paced: %v", b.ID, got.Params)
		}
	}
	// Explicit pacing wins.
	set := vault.Backend{ID: "d1", Type: "drive", Params: map[string]string{"pacer_min_sleep": "1s"}}
	if got := SharePacing(set, all); got.Params["pacer_min_sleep"] != "1s" || got.Params["pacer_burst"] != "50" {
		t.Fatalf("explicit pacing: %v", got.Params)
	}
}

// rclone must accept the values SharePacing writes.
func TestSharePacingParamsValid(t *testing.T) {
	b := SharePacing(vault.Backend{ID: "a", Type: "drive"}, []vault.Backend{{ID: "b", Type: "drive"}})
	if _, err := ObscureParams("drive", b.Params); err != nil {
		t.Fatal(err)
	}
}
