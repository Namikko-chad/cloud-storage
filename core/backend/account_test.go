package backend

import (
	"context"
	"testing"

	"cloudsync/core/vault"
)

func TestSameLocation(t *testing.T) {
	mega := func(user string) vault.Backend {
		return vault.Backend{Type: "mega", Root: "cloudsync", Params: map[string]string{"user": user}}
	}
	if !SameLocation(mega("A@x.com"), mega("a@x.com")) {
		t.Fatal("same Mega account must match (case-insensitive)")
	}
	if SameLocation(mega("a@x.com"), mega("b@x.com")) {
		t.Fatal("different accounts must not match")
	}
	drive := vault.Backend{Type: "drive", Root: "cloudsync"}
	if SameLocation(drive, drive) {
		t.Fatal("unknown account must not match")
	}
	acc := drive
	acc.Account = "me@gmail.com"
	if !SameLocation(acc, acc) {
		t.Fatal("recorded account must match")
	}
	local := func(root string) vault.Backend { return vault.Backend{Type: "local", Root: root} }
	if !SameLocation(local("/mnt/a"), local("/mnt/a/b")) || !SameLocation(local("/mnt/a/"), local("/mnt/a")) {
		t.Fatal("nested local folders must match")
	}
	if SameLocation(local("/mnt/a"), local("/mnt/ab")) {
		t.Fatal("sibling local folders must not match")
	}
}

func TestCompleteParamsNoop(t *testing.T) {
	ctx := context.Background()
	for _, c := range []struct {
		typ    string
		params map[string]string
	}{
		{"drive", map[string]string{"token": "x"}},
		{"onedrive", map[string]string{}},
		{"onedrive", map[string]string{"token": "x", "drive_id": "d", "drive_type": "personal"}},
	} {
		got, err := CompleteParams(ctx, c.typ, c.params)
		if err != nil || len(got) != len(c.params) {
			t.Fatalf("%s %v: got %v, %v", c.typ, c.params, got, err)
		}
	}
	if _, err := CompleteParams(ctx, "onedrive", map[string]string{"token": "not json"}); err == nil {
		t.Fatal("bad token accepted")
	}
}
