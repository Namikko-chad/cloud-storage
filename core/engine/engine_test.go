package engine

import (
	"bytes"
	"context"
	"errors"
	"io"
	"math/rand"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"cloudsync/core/backend"
	"cloudsync/core/chunker"
	"cloudsync/core/lock"
	"cloudsync/core/vault"
)

var fastKDF = vault.KDFParams{Time: 1, Memory: 1024, Threads: 1}

// world is a set of storages shared by simulated devices.
type world struct {
	t         *testing.T
	mem       map[string]*backend.MemStore
	vaultFile []byte
}

// newWorld makes a vault with k=2 m=1 over: two Mega accounts, Drive, S3.
func newWorld(t *testing.T) *world {
	c, _ := vault.New(2, 1)
	c.Backends = []vault.Backend{
		{ID: "mega1", Name: "Mega personal", Type: "mega"},
		{ID: "mega2", Name: "Mega work", Type: "mega"},
		{ID: "gd", Name: "Google Drive", Type: "drive"},
		{ID: "s3", Name: "S3", Type: "s3"},
	}
	path := filepath.Join(t.TempDir(), "vault.cs")
	if _, err := vault.Create(path, []byte("pw"), c, fastKDF); err != nil {
		t.Fatal(err)
	}
	data, _ := os.ReadFile(path)
	w := &world{t: t, mem: map[string]*backend.MemStore{}, vaultFile: data}
	for _, b := range c.Backends {
		w.mem[b.ID] = backend.NewMemStore(b.ID)
	}
	return w
}

// device opens the vault on a new device with its own vault file copy.
func (w *world) device(name string) *Engine {
	dir := w.t.TempDir()
	vp := filepath.Join(dir, "vault.cs")
	if err := os.WriteFile(vp, w.vaultFile, 0o600); err != nil {
		w.t.Fatal(err)
	}
	v, err := vault.Open(vp, []byte("pw"))
	if err != nil {
		w.t.Fatal(err)
	}
	return w.reopen(v, filepath.Join(dir, "data"), name)
}

func (w *world) reopen(v *vault.Vault, dataDir, name string) *Engine {
	e, err := Open(context.Background(), v, Options{
		DataDir:       dataDir,
		DeviceName:    name,
		Chunk:         chunker.Params{Min: 1 << 10, Avg: 4 << 10, Max: 16 << 10},
		PackThreshold: 2 << 10,
		PackSize:      16 << 10,
		OpenStore: func(_ context.Context, _ string, b vault.Backend) (backend.Store, error) {
			return w.mem[b.ID], nil
		},
	})
	if err != nil {
		w.t.Fatal(err)
	}
	w.t.Cleanup(func() { e.Close(context.Background()) })
	return e
}

func (w *world) offline(off bool, ids ...string) {
	for _, id := range ids {
		w.mem[id].SetOffline(off)
	}
}

func (w *world) objects(prefix string) int {
	n := 0
	for _, m := range w.mem {
		for name := range m.Objects() {
			if strings.HasPrefix(name, prefix) {
				n++
			}
		}
	}
	return n
}

func read(t *testing.T, e *Engine, p string) []byte {
	t.Helper()
	f, err := e.OpenFile(context.Background(), p)
	if err != nil {
		t.Fatal(err)
	}
	var buf bytes.Buffer
	if _, err := f.WriteTo(&buf); err != nil {
		t.Fatalf("read %s: %v", p, err)
	}
	return buf.Bytes()
}

func random(n int, seed int64) []byte {
	b := make([]byte, n)
	rand.New(rand.NewSource(seed)).Read(b)
	return b
}

func TestTwoDevices(t *testing.T) {
	ctx := context.Background()
	w := newWorld(t)
	a, b := w.device("laptop"), w.device("phone")

	big := random(200<<10, 1)
	if _, err := a.PutFile(ctx, "/photos/big.bin", bytes.NewReader(big), time.Now()); err != nil {
		t.Fatal(err)
	}
	var ups []Upload
	for i := 0; i < 10; i++ {
		ups = append(ups, UploadBytes("/notes/n"+string(rune('0'+i))+".txt", []byte(strings.Repeat("x", 100+i)), time.Now()))
	}
	before := w.objects("d/")
	if _, err := a.PutFiles(ctx, ups); err != nil {
		t.Fatal(err)
	}
	if got := w.objects("d/") - before; got != 3 {
		t.Fatalf("10 small files should be one pack = 3 shards, got %d objects", got)
	}

	if err := b.Sync(ctx); err != nil {
		t.Fatal(err)
	}
	if got := read(t, b, "/photos/big.bin"); !bytes.Equal(got, big) {
		t.Fatal("big file differs on B")
	}
	if got := read(t, b, "/notes/n7.txt"); string(got) != strings.Repeat("x", 107) {
		t.Fatalf("small file: %q", got)
	}
	// Random access fetches only what it needs.
	f, _ := b.OpenFile(ctx, "/photos/big.bin")
	buf := make([]byte, 1000)
	if _, err := f.ReadAt(buf, 150000); err != nil || !bytes.Equal(buf, big[150000:151000]) {
		t.Fatal("ReadAt", err)
	}
	if list, _ := b.List("/notes"); len(list) != 10 {
		t.Fatalf("list: %d", len(list))
	}

	// Nothing readable in storages.
	for _, m := range w.mem {
		for name, obj := range m.Objects() {
			if bytes.Contains(obj, big[:32]) || bytes.Contains(obj, []byte("xxxxxxxxxx")) || bytes.Contains(obj, []byte("photos")) {
				t.Fatalf("plaintext in %s", name)
			}
		}
	}
}

func TestOutagesAndRepair(t *testing.T) {
	ctx := context.Background()
	w := newWorld(t)
	a, b := w.device("laptop"), w.device("phone")
	data := random(100<<10, 2)

	w.offline(true, "gd")
	if _, err := a.PutFile(ctx, "/f.bin", bytes.NewReader(data), time.Now()); err != nil {
		t.Fatal("write with one storage down:", err)
	}
	w.offline(false, "gd")
	if err := b.Sync(ctx); err != nil {
		t.Fatal(err)
	}
	rep, err := b.Repair(ctx, RepairOptions{})
	if err != nil {
		t.Fatal(err)
	}
	if rep.Repaired == 0 {
		t.Fatalf("nothing repaired: %+v", rep)
	}
	// Now every storage may fail on its own.
	for id := range w.mem {
		w.offline(true, id)
		b.cache = mustCache(t)
		if got := read(t, b, "/f.bin"); !bytes.Equal(got, data) {
			t.Fatalf("with %s down", id)
		}
		w.offline(false, id)
	}
}

func mustCache(t *testing.T) *cache {
	c, err := newCache(t.TempDir(), 1<<30)
	if err != nil {
		t.Fatal(err)
	}
	return c
}

func TestConflict(t *testing.T) {
	ctx := context.Background()
	w := newWorld(t)
	a, b := w.device("laptop"), w.device("phone")
	a.PutFile(ctx, "/doc.txt", strings.NewReader("v1"), time.Now())
	b.Sync(ctx)
	a.PutFile(ctx, "/doc.txt", strings.NewReader("from laptop"), time.Now())
	b.PutFile(ctx, "/doc.txt", strings.NewReader("from phone"), time.Now())
	a.Sync(ctx)
	b.Sync(ctx)
	la, _ := a.List("/")
	lb, _ := b.List("/")
	if len(la) != 2 || len(lb) != 2 || la[0].Path != lb[0].Path {
		t.Fatalf("expected file + conflict copy on both: %v / %v", la, lb)
	}
	if !strings.Contains(la[0].Path, "conflict") || la[1].Path != "/doc.txt" {
		t.Fatal(la[0].Path, la[1].Path)
	}
	// Both versions survive, each readable.
	got := string(read(t, a, la[0].Path)) + "|" + string(read(t, a, "/doc.txt"))
	if got != "from phone|from laptop" && got != "from laptop|from phone" {
		t.Fatal(got)
	}
}

func TestPinsWorkOffline(t *testing.T) {
	ctx := context.Background()
	w := newWorld(t)
	a, b := w.device("laptop"), w.device("phone")
	a.PutFile(ctx, "/keep/a.bin", bytes.NewReader(random(50<<10, 3)), time.Now())
	a.PutFile(ctx, "/other/b.bin", bytes.NewReader(random(50<<10, 4)), time.Now())
	b.Sync(ctx)
	if b.IsLocal("/keep/a.bin") {
		t.Fatal("downloaded without being asked")
	}
	if err := b.Pin(ctx, "/keep"); err != nil {
		t.Fatal(err)
	}
	if !b.IsLocal("/keep/a.bin") || b.IsLocal("/other/b.bin") {
		t.Fatal("pin downloaded the wrong files")
	}
	// A pinned dir also covers files added later.
	a.PutFile(ctx, "/keep/new.txt", strings.NewReader("later"), time.Now())
	b.Sync(ctx)
	w.offline(true, "mega1", "mega2", "gd", "s3")
	if got := read(t, b, "/keep/new.txt"); string(got) != "later" {
		t.Fatal(string(got))
	}
	if _, err := b.OpenFile(ctx, "/other/b.bin"); err == nil {
		f, _ := b.OpenFile(ctx, "/other/b.bin")
		if _, err := f.WriteTo(io.Discard); err == nil {
			t.Fatal("unpinned file read with all storages down")
		}
	}
}

func TestOfflineChangesAreQueued(t *testing.T) {
	ctx := context.Background()
	w := newWorld(t)
	a, b := w.device("laptop"), w.device("phone")
	w.offline(true, "mega1", "mega2", "gd", "s3")
	if err := a.Mkdir(ctx, "/made offline"); err != nil {
		t.Fatal(err)
	}
	if a.Pending() != 1 {
		t.Fatal("not queued")
	}
	w.offline(false, "mega1", "mega2", "gd", "s3")
	a.Sync(ctx)
	if a.Pending() != 0 {
		t.Fatal("still pending")
	}
	b.Sync(ctx)
	if _, err := b.Stat("/made offline"); err != nil {
		t.Fatal(err)
	}
}

func TestRestartKeepsState(t *testing.T) {
	ctx := context.Background()
	w := newWorld(t)
	dir := t.TempDir()
	vp := filepath.Join(dir, "vault.cs")
	os.WriteFile(vp, w.vaultFile, 0o600)
	v, _ := vault.Open(vp, []byte("pw"))
	a := w.reopen(v, filepath.Join(dir, "data"), "laptop")
	a.PutFile(ctx, "/x", strings.NewReader("1"), time.Now())
	id := a.DeviceID()
	a.Close(ctx)
	a2 := w.reopen(v, filepath.Join(dir, "data"), "laptop")
	if a2.DeviceID() != id {
		t.Fatal("device id changed")
	}
	a2.PutFile(ctx, "/x", strings.NewReader("2"), time.Now())
	b := w.device("phone")
	if got := read(t, b, "/x"); string(got) != "2" {
		t.Fatalf("got %q (seq reused?)", got)
	}
	if list, _ := b.List("/"); len(list) != 1 {
		t.Fatalf("unexpected conflict: %v", list)
	}
}

func TestRenameRemove(t *testing.T) {
	ctx := context.Background()
	w := newWorld(t)
	a := w.device("laptop")
	a.PutFile(ctx, "/d/sub/f.txt", strings.NewReader("hello"), time.Now())
	if err := a.Rename(ctx, "/d", "/e"); err != nil {
		t.Fatal(err)
	}
	if got := read(t, a, "/e/sub/f.txt"); string(got) != "hello" {
		t.Fatal(string(got))
	}
	if _, err := a.Stat("/d"); err == nil {
		t.Fatal("old dir left")
	}
	if err := a.Remove(ctx, "/e", false); !errors.Is(err, ErrNotEmpty) {
		t.Fatal(err)
	}
	if err := a.Remove(ctx, "/e", true); err != nil {
		t.Fatal(err)
	}
	if l, _ := a.List("/"); len(l) != 0 {
		t.Fatal(l)
	}
}

func TestLocks(t *testing.T) {
	ctx := context.Background()
	w := newWorld(t)
	a, b := w.device("laptop"), w.device("phone")
	l, err := a.Lock(ctx, "/doc.txt")
	if err != nil {
		t.Fatal(err)
	}
	_, err = b.Lock(ctx, "doc.txt")
	var le *lock.LockedError
	if !errors.As(err, &le) || le.Holder.DeviceName != "laptop" {
		t.Fatalf("phone got the lock: %v", err)
	}
	l.Release(ctx)
	if _, err := b.Lock(ctx, "/doc.txt"); err != nil {
		t.Fatal(err)
	}
}

func TestRemoveStorage(t *testing.T) {
	ctx := context.Background()
	w := newWorld(t)
	dir := t.TempDir()
	vp := filepath.Join(dir, "vault.cs")
	os.WriteFile(vp, w.vaultFile, 0o600)
	v, _ := vault.Open(vp, []byte("pw"))
	a := w.reopen(v, filepath.Join(dir, "data"), "laptop")
	data := random(80<<10, 5)
	a.PutFile(ctx, "/f", bytes.NewReader(data), time.Now())
	a.Close(ctx)

	v.Update(func(c *vault.Config) error {
		for i := range c.Backends {
			if c.Backends[i].ID == "s3" {
				c.Backends[i].Disabled = true
			}
		}
		return nil
	})
	a = w.reopen(v, filepath.Join(dir, "data"), "laptop")
	if _, err := a.Repair(ctx, RepairOptions{}); err != nil {
		t.Fatal(err)
	}
	w.mem["s3"].Wipe()
	w.offline(true, "s3")
	b := w.device("phone") // has the old vault, still lists s3: must cope
	if got := read(t, b, "/f"); !bytes.Equal(got, data) {
		t.Fatal("lost data after removing a storage")
	}
	// One more failure is still survivable.
	b.cache = mustCache(t)
	w.offline(true, "gd")
	if got := read(t, b, "/f"); !bytes.Equal(got, data) {
		t.Fatal("no redundancy left after moving shards")
	}
}

func TestVaultSpreadsToDevices(t *testing.T) {
	ctx := context.Background()
	w := newWorld(t)
	a, b := w.device("laptop"), w.device("phone")
	a.Sync(ctx)
	if err := a.v.Update(func(c *vault.Config) error {
		c.Backends = append(c.Backends, vault.Backend{ID: "webdav", Name: "NAS", Type: "webdav"})
		return nil
	}); err != nil {
		t.Fatal(err)
	}
	a.Sync(ctx)
	b.Sync(ctx)
	if _, ok := b.v.Config().Backend("webdav"); !ok {
		t.Fatal("new storage did not reach the phone")
	}
	if !b.Status(ctx).ReloadNeeded {
		t.Fatal("reload not flagged")
	}
}

func TestDomainRisk(t *testing.T) {
	c := &vault.Config{DataShards: 2, ParityShards: 1, Backends: []vault.Backend{
		{ID: "1", Type: "mega"}, {ID: "2", Type: "mega"}, {ID: "3", Type: "drive"},
	}}
	if !DomainRisk(c) {
		t.Fatal("2 of 3 shards on Mega: a Mega outage loses data")
	}
	c.Backends = append(c.Backends, vault.Backend{ID: "4", Type: "s3"})
	if DomainRisk(c) {
		t.Fatal("4 storages in 3 domains for k+m=3 is safe")
	}
}

func TestDataDirSingleProcess(t *testing.T) {
	w := newWorld(t)
	dir := t.TempDir()
	vp := filepath.Join(dir, "vault.cs")
	os.WriteFile(vp, w.vaultFile, 0o600)
	v, _ := vault.Open(vp, []byte("pw"))
	a := w.reopen(v, filepath.Join(dir, "data"), "laptop")
	_, err := Open(context.Background(), v, Options{DataDir: filepath.Join(dir, "data"),
		OpenStore: func(_ context.Context, _ string, b vault.Backend) (backend.Store, error) { return w.mem[b.ID], nil }})
	if err == nil {
		t.Fatal("second process opened the same data dir")
	}
	a.Close(context.Background())
	if _, err := Open(context.Background(), v, Options{DataDir: filepath.Join(dir, "data"),
		OpenStore: func(_ context.Context, _ string, b vault.Backend) (backend.Store, error) { return w.mem[b.ID], nil }}); err != nil {
		t.Fatal("data dir still locked after Close:", err)
	}
}

// openOwn returns a device with its own vault file, so the test can change
// the vault and reopen.
func (w *world) openOwn(name string) (*vault.Vault, string, *Engine) {
	dir := w.t.TempDir()
	vp := filepath.Join(dir, "vault.cs")
	os.WriteFile(vp, w.vaultFile, 0o600)
	v, err := vault.Open(vp, []byte("pw"))
	if err != nil {
		w.t.Fatal(err)
	}
	data := filepath.Join(dir, "data")
	return v, data, w.reopen(v, data, name)
}

func TestGC(t *testing.T) {
	ctx := context.Background()
	w := newWorld(t)
	a := w.device("laptop")
	keep, drop := random(60<<10, 1), random(60<<10, 2)
	a.PutFile(ctx, "/keep", bytes.NewReader(keep), time.Now())
	a.PutFile(ctx, "/drop", bytes.NewReader(drop), time.Now())
	a.PutFile(ctx, "/keep", bytes.NewReader(append(keep, 'x')), time.Now()) // old version is garbage too
	before := w.objects("d/")
	if err := a.Remove(ctx, "/drop", false); err != nil {
		t.Fatal(err)
	}
	rep, err := a.GC(ctx, time.Hour)
	if err != nil || rep.Deleted != 0 || rep.Unused == 0 {
		t.Fatalf("first gc: %+v %v", rep, err)
	}
	if w.objects("d/") != before {
		t.Fatal("deleted before the grace period")
	}
	rep, err = a.GC(ctx, 0)
	if err != nil || rep.Deleted != rep.Unused || rep.Deleted == 0 {
		t.Fatalf("second gc: %+v %v", rep, err)
	}
	b := w.device("phone")
	if got := read(t, b, "/keep"); !bytes.Equal(got, append(keep, 'x')) {
		t.Fatal("live file damaged by gc")
	}
	// An unused object that becomes used again is not deleted later.
	rep, _ = a.GC(ctx, 0)
	if rep.Unused != 0 {
		t.Fatalf("garbage left: %+v", rep)
	}
}

func TestRedundancyChange(t *testing.T) {
	ctx := context.Background()
	w := newWorld(t)
	v, data, a := w.openOwn("laptop")
	content := random(100<<10, 3)
	a.PutFile(ctx, "/f", bytes.NewReader(content), time.Now())
	if err := a.SetRedundancy(2, 3); err == nil {
		t.Fatal("k+m above the number of storages accepted")
	}
	if err := a.SetRedundancy(2, 2); err != nil {
		t.Fatal(err)
	}
	if !a.ReloadNeeded() {
		t.Fatal("no reload requested")
	}
	a.Close(ctx)
	a = w.reopen(v, data, "laptop")
	rep, err := a.Repair(ctx, RepairOptions{})
	if err != nil || rep.Reencoded == 0 {
		t.Fatalf("repair: %+v %v", rep, err)
	}
	if err := a.Sync(ctx); err != nil {
		t.Fatal(err)
	}
	// Two storages may fail now, for a device that still has the old vault.
	b := w.device("phone")
	w.offline(true, "mega1", "s3")
	if got := read(t, b, "/f"); !bytes.Equal(got, content) {
		t.Fatal("not readable with two storages down after k/m change")
	}
	w.offline(false, "mega1", "s3")
	if rep, err := a.GC(ctx, 0); err != nil || rep.Deleted == 0 {
		t.Fatalf("old shards not collected: %+v %v", rep, err)
	}
	b.cache = mustCache(t)
	if got := read(t, b, "/f"); !bytes.Equal(got, content) {
		t.Fatal("gc removed the new generation")
	}
}

func TestRebalance(t *testing.T) {
	ctx := context.Background()
	w := newWorld(t)
	v, data, a := w.openOwn("laptop")
	files := map[string][]byte{}
	for i := 0; i < 8; i++ {
		p := "/f" + string(rune('a'+i))
		files[p] = random(40<<10, int64(10+i))
		a.PutFile(ctx, p, bytes.NewReader(files[p]), time.Now())
	}
	a.Close(ctx)
	w.mem["new"] = backend.NewMemStore("new")
	v.Update(func(c *vault.Config) error {
		c.Backends = append(c.Backends, vault.Backend{ID: "new", Name: "New", Type: "webdav"})
		return nil
	})
	a = w.reopen(v, data, "laptop")
	rep, err := a.Repair(ctx, RepairOptions{Rebalance: true})
	if err != nil || rep.Moved == 0 {
		t.Fatalf("rebalance: %+v %v", rep, err)
	}
	if n := len(w.mem["new"].Objects()); n == 0 {
		t.Fatal("nothing moved to the new storage")
	}
	if _, err := a.GC(ctx, 0); err != nil {
		t.Fatal(err)
	}
	b := w.device("phone")
	w.offline(true, "gd")
	for p, want := range files {
		if got := read(t, b, p); !bytes.Equal(got, want) {
			t.Fatalf("%s damaged by rebalance", p)
		}
	}
}

func TestRemoveBackend(t *testing.T) {
	ctx := context.Background()
	w := newWorld(t)
	v, data, a := w.openOwn("laptop")
	a.PutFile(ctx, "/f", bytes.NewReader(random(50<<10, 4)), time.Now())
	if err := a.RemoveBackend("s3", false); err == nil {
		t.Fatal("removed an enabled storage")
	}
	v.Update(func(c *vault.Config) error {
		for i := range c.Backends {
			if c.Backends[i].ID == "s3" {
				c.Backends[i].Disabled = true
			}
		}
		return nil
	})
	a.Close(ctx)
	a = w.reopen(v, data, "laptop")
	if err := a.RemoveBackend("s3", false); err == nil && usesStore(a, "s3") {
		t.Fatal("removed a storage that still holds shards")
	}
	if _, err := a.Repair(ctx, RepairOptions{}); err != nil {
		t.Fatal(err)
	}
	if err := a.RemoveBackend("s3", false); err != nil {
		t.Fatal(err)
	}
	if _, ok := v.Config().Backend("s3"); ok {
		t.Fatal("still in the vault")
	}
}

func usesStore(e *Engine, id string) bool {
	for _, r := range e.liveBlobs() {
		for _, s := range r.Placement {
			if s == id {
				return true
			}
		}
	}
	return false
}

// One storage down is not a failed sync: the others carry the journal and
// the vault copy; the storage's own status shows it.
func TestSyncWithOneStorageDown(t *testing.T) {
	ctx := context.Background()
	w := newWorld(t)
	a, b := w.device("laptop"), w.device("phone")
	w.offline(true, "gd")
	if _, err := a.PutFile(ctx, "/x.txt", bytes.NewReader([]byte("hello")), time.Now()); err != nil {
		t.Fatal(err)
	}
	if err := a.Sync(ctx); err != nil {
		t.Fatalf("sync with one storage down: %v", err)
	}
	if err := b.Sync(ctx); err != nil {
		t.Fatalf("sync with one storage down: %v", err)
	}
	if got := read(t, b, "/x.txt"); string(got) != "hello" {
		t.Fatalf("got %q", got)
	}
	w.offline(true, "mega1", "mega2", "s3")
	if err := a.Sync(ctx); err == nil {
		t.Fatal("sync with every storage down must fail")
	}
}

// A disabled storage is not asked on sync (journal, locks, vault copy),
// only for shards; one that is gone can be removed by force, and Repair
// names the files it cannot rebuild.
func TestDisabledStorageGone(t *testing.T) {
	ctx := context.Background()
	w := newWorld(t)
	v, data, a := w.openOwn("laptop")
	if _, err := a.PutFile(ctx, "/f", bytes.NewReader(random(50<<10, 5)), time.Now()); err != nil {
		t.Fatal(err)
	}
	if err := a.Sync(ctx); err != nil {
		t.Fatal(err)
	}
	v.Update(func(c *vault.Config) error {
		for i := range c.Backends {
			if c.Backends[i].ID == "s3" {
				c.Backends[i].Disabled = true
			}
		}
		return nil
	})
	a.Close(ctx)
	a = w.reopen(v, data, "laptop")
	journalOn := func(id string) int {
		n := 0
		for name := range w.mem[id].Objects() {
			if strings.HasPrefix(name, "j/") {
				n++
			}
		}
		return n
	}
	before := journalOn("s3")
	if _, err := a.PutFile(ctx, "/g", bytes.NewReader([]byte("new")), time.Now()); err != nil {
		t.Fatal(err)
	}
	if err := a.Sync(ctx); err != nil {
		t.Fatal(err)
	}
	if got := journalOn("s3"); got != before {
		t.Fatalf("journal written to a disabled storage: %d -> %d objects", before, got)
	}
	w.offline(true, "s3")
	if err := a.Sync(ctx); err != nil {
		t.Fatalf("sync with a disabled storage gone: %v", err)
	}
	if !usesStore(a, "s3") {
		t.Skip("placement did not use s3")
	}
	// Lose one more shard of every blob on s3: k=2 of 3, so they are gone.
	for _, r := range a.liveBlobs() {
		for _, sh := range a.blobs.Shards(r) {
			if sh.Store != "s3" {
				w.mem[sh.Store].Delete(ctx, sh.Name)
				break
			}
		}
	}
	a.cache, _ = newCache(t.TempDir(), 0) // no local copy to rebuild from
	rep, err := a.Repair(ctx, RepairOptions{})
	if err == nil || len(rep.Damaged) != 1 || rep.Damaged[0] != "/f" {
		t.Fatalf("repair: damaged %v, err %v", rep.Damaged, err)
	}
	if err := a.RemoveBackend("s3", false); err == nil {
		t.Fatal("removed a storage holding shards without force")
	}
	if err := a.RemoveBackend("s3", true); err != nil {
		t.Fatal(err)
	}
	if _, ok := v.Config().Backend("s3"); ok {
		t.Fatal("still in the vault")
	}
}

// Blobs with too few shards left in the storages are rebuilt from this
// device's copy (a pinned or read file), and other devices read them again.
func TestRepairFromLocalCopy(t *testing.T) {
	ctx := context.Background()
	w := newWorld(t)
	a, b := w.device("laptop"), w.device("phone")
	want := random(50<<10, 6)
	if _, err := a.PutFile(ctx, "/f", bytes.NewReader(want), time.Now()); err != nil {
		t.Fatal(err)
	}
	read(t, a, "/f") // now in a's cache
	if err := b.Sync(ctx); err != nil {
		t.Fatal(err)
	}
	// Leave one shard of every blob: k=2, so nobody can read /f.
	for _, r := range a.liveBlobs() {
		for _, sh := range a.blobs.Shards(r)[1:] {
			w.mem[sh.Store].Delete(ctx, sh.Name)
		}
	}
	rep, err := a.Repair(ctx, RepairOptions{})
	if err != nil {
		t.Fatalf("repair: %v (damaged %v)", err, rep.Damaged)
	}
	if rep.FromLocal == 0 || len(rep.Damaged) != 0 {
		t.Fatalf("from local %d, damaged %v", rep.FromLocal, rep.Damaged)
	}
	if got := read(t, b, "/f"); !bytes.Equal(got, want) {
		t.Fatal("phone reads other content")
	}
}
