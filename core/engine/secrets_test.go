package engine

import (
	"bytes"
	"context"
	"io/fs"
	"os"
	"path/filepath"
	"testing"

	"cloudsync/core/secrets"
)

func TestSafeSync(t *testing.T) {
	ctx := context.Background()
	w := newWorld(t)
	a, b := w.device("laptop"), w.device("phone")

	g, err := a.PutSecretGroup(ctx, "", secrets.GroupMeta{Name: "Work", Icon: []byte("\x89PNG\r\n\x1a\nxx")})
	if err != nil {
		t.Fatal(err)
	}
	en, err := a.PutSecret(ctx, "", "", secrets.Meta{Kind: secrets.KindPassword, Title: "Mail", Group: g.ID, Username: "me"},
		secrets.Data{Password: "hunter2-very-secret", Notes: "recovery-code-777"})
	if err != nil {
		t.Fatal(err)
	}
	evm, err := a.PutSecret(ctx, "", "", secrets.Meta{Kind: secrets.KindWeb3, Title: "Wallet"},
		secrets.Data{PrivateKey: "0x4c0883a69102937d6231471b5dbb6204fe5129617082792ae468d01a3f362318"})
	if err != nil || evm.Address != "0x2c7536E3605D9C16a7a3D7b1898e529396a65c23" || evm.Network != secrets.NetworkEVM {
		t.Fatalf("web3 entry: %+v %v", evm, err)
	}
	if _, err := a.PutSecret(ctx, "", "", secrets.Meta{Kind: secrets.KindSSH, Title: "bad"}, secrets.Data{PrivateKey: "nope"}); err == nil {
		t.Fatal("bad SSH key saved")
	}

	if err := b.Sync(ctx); err != nil {
		t.Fatal(err)
	}
	list := b.Safe()
	if len(list.Groups) != 1 || list.Groups[0].Name != "Work" || len(list.Entries) != 2 || list.Broken != 0 {
		t.Fatalf("other device sees %+v", list)
	}
	for _, e := range list.Entries {
		if e.Data != nil {
			t.Fatal("list carries secret data")
		}
	}
	got, err := b.OpenSecret(en.ID)
	if err != nil || got.Data.Password != "hunter2-very-secret" || got.Group != g.ID || got.Username != "me" {
		t.Fatalf("opened %+v %v", got, err)
	}

	// Both edit the same version: one wins, the other is kept as a copy.
	if _, err := a.PutSecret(ctx, en.ID, en.Version, got.Meta, secrets.Data{Password: "from-laptop"}); err != nil {
		t.Fatal(err)
	}
	if _, err := b.PutSecret(ctx, en.ID, en.Version, got.Meta, secrets.Data{Password: "from-phone"}); err != nil {
		t.Fatal(err)
	}
	a.Sync(ctx)
	b.Sync(ctx)
	a.Sync(ctx)
	pw := map[string]bool{}
	var copyID string
	for _, e := range a.Safe().Entries {
		if e.Title != "Mail" {
			continue
		}
		o, err := a.OpenSecret(e.ID)
		if err != nil {
			t.Fatal(err)
		}
		pw[o.Data.Password] = true
		if e.ConflictOf == en.ID {
			copyID = e.ID
		}
	}
	if !pw["from-laptop"] || !pw["from-phone"] || copyID == "" {
		t.Fatalf("concurrent edits: %v, copy %q", pw, copyID)
	}
	if len(a.Safe().Entries) != len(b.Safe().Entries) {
		t.Fatal("devices disagree")
	}
	if err := a.DeleteSecret(ctx, copyID); err != nil {
		t.Fatal(err)
	}
	if err := a.DeleteSecret(ctx, g.ID); err != nil {
		t.Fatal(err)
	}
	b.Sync(ctx)
	if l := b.Safe(); len(l.Entries) != 2 || len(l.Groups) != 0 {
		t.Fatalf("after deletes: %+v", l)
	}

	// Nothing readable on this device's disk or in the storages.
	for _, dir := range []string{a.opt.DataDir, b.opt.DataDir} {
		filepath.WalkDir(dir, func(p string, d fs.DirEntry, err error) error {
			if err != nil || d.IsDir() {
				return err
			}
			data, _ := os.ReadFile(p)
			for _, s := range []string{"hunter2", "recovery-code", "from-laptop", "4c0883a6", "Mail"} {
				if bytes.Contains(data, []byte(s)) {
					t.Errorf("%s holds %q in the clear", p, s)
				}
			}
			return nil
		})
	}
	objects := 0
	for id, m := range w.mem {
		var walk func(dir string)
		walk = func(dir string) {
			names, _ := m.List(ctx, dir)
			for _, n := range names {
				objects++
				data, _ := m.Get(ctx, n)
				if bytes.Contains(data, []byte("hunter2")) {
					t.Errorf("storage %s object %s holds a password", id, n)
				}
			}
			dirs, _ := m.ListDirs(ctx, dir)
			for _, d := range dirs {
				walk(d)
			}
		}
		walk("")
	}
	if objects == 0 {
		t.Fatal("no objects checked")
	}
}
