package vault

import (
	"bytes"
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"testing"
)

var fastKDF = KDFParams{Time: 1, Memory: 1024, Threads: 1}

func newVault(t *testing.T) (*Vault, string) {
	t.Helper()
	c, err := New(2, 1)
	if err != nil {
		t.Fatal(err)
	}
	c.Backends = []Backend{
		{ID: "a", Name: "Mega 1", Type: "mega", Params: map[string]string{"user": "one@x"}},
		{ID: "b", Name: "Mega 2", Type: "mega", Params: map[string]string{"user": "two@x"}},
	}
	path := filepath.Join(t.TempDir(), "vault.cs")
	v, err := Create(path, []byte("secret"), c, fastKDF)
	if err != nil {
		t.Fatal(err)
	}
	return v, path
}

func TestRoundTrip(t *testing.T) {
	v, path := newVault(t)
	if _, err := Create(path, []byte("x"), v.Config(), fastKDF); err == nil {
		t.Fatal("overwrote existing vault")
	}
	if _, err := Open(path, []byte("wrong")); !errors.Is(err, ErrBadPassword) {
		t.Fatalf("wrong password: %v", err)
	}
	v2, err := Open(path, []byte("secret"))
	if err != nil {
		t.Fatal(err)
	}
	c := v2.Config()
	if c.VaultID != v.Config().VaultID || len(c.Backends) != 2 || c.Backends[1].Params["user"] != "two@x" {
		t.Fatalf("config not preserved: %+v", c)
	}
	raw, _ := os.ReadFile(path)
	if bytes.Contains(raw, []byte("two@x")) {
		t.Fatal("plaintext in file")
	}
}

func TestDuplicateBackendRejected(t *testing.T) {
	v, _ := newVault(t)
	err := v.Update(func(c *Config) error {
		c.Backends = append(c.Backends, Backend{ID: "a", Type: "s3"})
		return nil
	})
	if err == nil {
		t.Fatal("duplicate id accepted")
	}
	if len(v.Config().Backends) != 2 {
		t.Fatal("failed update changed config")
	}
}

func TestMergeAndPassword(t *testing.T) {
	v, path := newVault(t)
	other, _ := Open(path, []byte("secret"))
	if err := other.Update(func(c *Config) error {
		c.Devices = append(c.Devices, Device{ID: "phone"})
		return nil
	}); err != nil {
		t.Fatal(err)
	}
	remote, _ := other.Encode()
	changed, err := v.Merge(remote)
	if err != nil || !changed || len(v.Config().Devices) != 1 {
		t.Fatalf("merge: %v %v", changed, err)
	}
	if changed, _ := v.Merge(remote); changed {
		t.Fatal("same version merged twice")
	}

	if err := v.ChangePassword([]byte("new"), fastKDF); err != nil {
		t.Fatal(err)
	}
	if _, err := Open(path, []byte("secret")); err == nil {
		t.Fatal("old password still works")
	}
	if _, err := Open(path, []byte("new")); err != nil {
		t.Fatal(err)
	}
	if _, err := v.Merge(remote); !errors.Is(err, ErrBadPassword) {
		t.Fatalf("copy with old password: %v", err)
	}
	enc, _ := v.Encode()
	if _, err := Decode(enc, []byte("new")); err != nil {
		t.Fatal(err)
	}
}

func TestMergeConcurrentChanges(t *testing.T) {
	dir := t.TempDir()
	c, _ := New(2, 1)
	a, err := Create(filepath.Join(dir, "a.cs"), []byte("pw"), c, fastKDF)
	if err != nil {
		t.Fatal(err)
	}
	data, _ := a.Encode()
	os.WriteFile(filepath.Join(dir, "b.cs"), data, 0o600)
	b, _ := Open(filepath.Join(dir, "b.cs"), []byte("pw"))

	// Both change the same version at once.
	a.Update(func(c *Config) error {
		c.Devices = append(c.Devices, Device{ID: "A"})
		c.Backends = append(c.Backends, Backend{ID: "x", Type: "local"})
		return nil
	})
	b.Update(func(c *Config) error {
		c.Devices = append(c.Devices, Device{ID: "B"})
		return nil
	})
	da, _ := a.Encode()
	db, _ := b.Encode()
	if ok, err := a.Merge(db); !ok || err != nil {
		t.Fatal("equal versions with different content not merged", err)
	}
	if ok, err := b.Merge(da); !ok || err != nil {
		t.Fatal(err)
	}
	// Exchange once more: both must end at the same config.
	da, _ = a.Encode()
	db, _ = b.Encode()
	a.Merge(db)
	b.Merge(da)
	ca, cb := a.Config(), b.Config()
	ja, _ := json.Marshal(ca)
	jb, _ := json.Marshal(cb)
	if string(ja) != string(jb) {
		t.Fatalf("diverged:\n%s\n%s", ja, jb)
	}
	if len(ca.Devices) != 2 || len(ca.Backends) != 1 {
		t.Fatalf("lost changes: %+v", ca)
	}
}
