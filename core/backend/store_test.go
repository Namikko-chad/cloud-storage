package backend

import (
	"context"
	"errors"
	"os"
	"path/filepath"
	"reflect"
	"testing"

	"cloudsync/core/eventlog"
	"cloudsync/core/vault"
)

func conformance(t *testing.T, s Store) {
	ctx := context.Background()
	if _, err := s.Get(ctx, "x/missing"); !errors.Is(err, ErrNotFound) {
		t.Fatalf("missing object: %v", err)
	}
	if l, err := s.List(ctx, "nodir"); err != nil || len(l) != 0 {
		t.Fatalf("missing dir: %v %v", l, err)
	}
	for _, n := range []string{"j/dev1/1", "j/dev1/2", "j/dev2/1", "j/top"} {
		if err := s.Put(ctx, n, []byte(n)); err != nil {
			t.Fatal(err)
		}
	}
	if err := s.Put(ctx, "j/top", []byte("v2")); err != nil {
		t.Fatal(err)
	}
	if d, err := s.Get(ctx, "j/top"); err != nil || string(d) != "v2" {
		t.Fatalf("overwrite: %q %v", d, err)
	}
	if l, _ := s.List(ctx, "j/dev1"); !reflect.DeepEqual(l, []string{"j/dev1/1", "j/dev1/2"}) {
		t.Fatalf("list: %v", l)
	}
	if l, _ := s.List(ctx, "j"); !reflect.DeepEqual(l, []string{"j/top"}) {
		t.Fatalf("list files only: %v", l)
	}
	if l, _ := s.ListDirs(ctx, "j"); !reflect.DeepEqual(l, []string{"j/dev1", "j/dev2"}) {
		t.Fatalf("list dirs: %v", l)
	}
	if err := s.Delete(ctx, "j/dev1/1"); err != nil {
		t.Fatal(err)
	}
	if err := s.Delete(ctx, "j/dev1/1"); err != nil {
		t.Fatal("delete of missing object failed")
	}
	if _, err := s.Get(ctx, "j/dev1/1"); !errors.Is(err, ErrNotFound) {
		t.Fatal("deleted object still there")
	}
}

func TestMemStore(t *testing.T) { conformance(t, NewMemStore("m")) }

// Two accounts of the same type must be fully independent.
func TestRcloneSameTypeTwice(t *testing.T) {
	dirA, dirB := t.TempDir(), t.TempDir()
	ctx := context.Background()
	a, err := OpenRclone(ctx, "vault1", vault.Backend{ID: "a", Name: "A", Type: "local", Root: dirA}, nil)
	if err != nil {
		t.Fatal(err)
	}
	b, err := OpenRclone(ctx, "vault1", vault.Backend{ID: "b", Name: "B", Type: "local", Root: dirB}, nil)
	if err != nil {
		t.Fatal(err)
	}
	conformance(t, a)
	if l, _ := b.List(ctx, "j/dev1"); len(l) != 0 {
		t.Fatalf("backends share data: %v", l)
	}
	if _, err := os.Stat(filepath.Join(dirA, "vault1", "j", "top")); err != nil {
		t.Fatal("objects not under <root>/<vault>")
	}
}

func TestObscureParams(t *testing.T) {
	p, err := ObscureParams("mega", map[string]string{"user": "u", "pass": "secret"})
	if err != nil {
		t.Fatal(err)
	}
	if p["user"] != "u" || p["pass"] == "secret" || p["pass"] == "" {
		t.Fatalf("%v", p)
	}
	again, _ := ObscureParams("mega", p)
	if again["pass"] != p["pass"] {
		t.Fatal("obscured twice")
	}
}

func TestRcloneAbout(t *testing.T) {
	ctx := context.Background()
	s, err := OpenRclone(ctx, "vault1", vault.Backend{ID: "a", Name: "A", Type: "local", Root: t.TempDir()}, nil)
	if err != nil {
		t.Fatal(err)
	}
	// Through Logged, as the engine opens it.
	u, err := About(ctx, Logged(s, "A", eventlog.New(10, nil)))
	if err != nil {
		t.Fatal(err)
	}
	if u.Total <= 0 || u.Free <= 0 || u.Free > u.Total {
		t.Fatalf("disk usage %+v", u)
	}
	if _, err := About(ctx, NewMemStore("m")); err != ErrNoUsage {
		t.Fatalf("mem store without quota: %v", err)
	}
}
