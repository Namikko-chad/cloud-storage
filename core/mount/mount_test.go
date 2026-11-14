//go:build !android

package mount

import (
	"context"
	"io"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/winfsp/cgofuse/fuse"

	"cloudsync/core/backend"
	"cloudsync/core/chunker"
	"cloudsync/core/engine"
	"cloudsync/core/vault"
)

// gate holds shard uploads ("d/...") until it is opened.
type gate struct {
	*backend.MemStore
	mu   sync.Mutex
	open chan struct{}
}

func (g *gate) Put(ctx context.Context, name string, data []byte) error {
	if strings.HasPrefix(name, "d/") {
		g.mu.Lock()
		ch := g.open
		g.mu.Unlock()
		select {
		case <-ch:
		case <-ctx.Done():
			return ctx.Err()
		}
	}
	return g.MemStore.Put(ctx, name, data)
}

type rig struct {
	t       *testing.T
	fs      *FS
	e       *engine.Engine
	staging string
	gates   []*gate
}

func newRig(t *testing.T) *rig {
	c, _ := vault.New(2, 1)
	c.Backends = []vault.Backend{
		{ID: "a", Name: "A", Type: "mega"},
		{ID: "b", Name: "B", Type: "drive"},
		{ID: "c", Name: "C", Type: "s3"},
	}
	dir := t.TempDir()
	vp := filepath.Join(dir, "vault.cs")
	v, err := vault.Create(vp, []byte("pw"), c, vault.KDFParams{Time: 1, Memory: 1024, Threads: 1})
	if err != nil {
		t.Fatal(err)
	}
	r := &rig{t: t, staging: filepath.Join(dir, "staging")}
	stores := map[string]*gate{}
	for _, b := range c.Backends {
		g := &gate{MemStore: backend.NewMemStore(b.ID), open: make(chan struct{})}
		close(g.open)
		stores[b.ID] = g
		r.gates = append(r.gates, g)
	}
	r.e, err = engine.Open(context.Background(), v, engine.Options{
		DataDir:       filepath.Join(dir, "data"),
		DeviceName:    "laptop",
		Chunk:         chunker.Params{Min: 1 << 10, Avg: 4 << 10, Max: 16 << 10},
		PackThreshold: 2 << 10,
		PackSize:      16 << 10,
		OpenStore: func(_ context.Context, _ string, b vault.Backend) (backend.Store, error) {
			return stores[b.ID], nil
		},
	})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { r.e.Close(context.Background()) })
	r.fs = r.newFS()
	return r
}

func (r *rig) newFS() *FS {
	f, err := New(r.e, r.staging)
	if err != nil {
		r.t.Fatal(err)
	}
	f.Linger = 10 * time.Millisecond
	return f
}

// hold makes shard uploads wait until the returned function is called.
func (r *rig) hold() (release func()) {
	ch := make(chan struct{})
	for _, g := range r.gates {
		g.mu.Lock()
		g.open = ch
		g.mu.Unlock()
	}
	return func() { close(ch) }
}

// write creates p with data through the file system and closes it.
func (r *rig) write(p, data string) {
	r.t.Helper()
	rc, fh := r.fs.Create(p, fuse.O_WRONLY, 0o644)
	if rc != 0 {
		r.t.Fatalf("create %s: %d", p, rc)
	}
	if n := r.fs.Write(p, []byte(data), 0, fh); n != len(data) {
		r.t.Fatalf("write %s: %d", p, n)
	}
	done := make(chan int, 1)
	go func() { done <- r.fs.Release(p, fh) }()
	select {
	case <-done:
	case <-time.After(5 * time.Second):
		r.t.Fatalf("close of %s waits for the upload", p)
	}
}

// read reads p through the file system.
func (r *rig) read(p string) string {
	r.t.Helper()
	rc, fh := r.fs.Open(p, fuse.O_RDONLY)
	if rc != 0 {
		r.t.Fatalf("open %s: %d", p, rc)
	}
	defer r.fs.Release(p, fh)
	buf := make([]byte, 1<<16)
	n := r.fs.Read(p, buf, 0, fh)
	if n < 0 {
		r.t.Fatalf("read %s: %d", p, n)
	}
	return string(buf[:n])
}

// idle waits until no upload runs.
func (r *rig) idle() {
	r.t.Helper()
	deadline := time.Now().Add(10 * time.Second)
	for {
		r.fs.mu.Lock()
		n := len(r.fs.uploading) + len(r.fs.inflight)
		r.fs.mu.Unlock()
		if n == 0 {
			return
		}
		if time.Now().After(deadline) {
			r.t.Fatal("uploads do not finish")
		}
		time.Sleep(5 * time.Millisecond)
	}
}

// stored returns the content of p in the vault ("" and false if absent).
func (r *rig) stored(p string) (string, bool) {
	f, err := r.e.OpenFile(context.Background(), p)
	if err != nil {
		return "", false
	}
	var sb strings.Builder
	if _, err := io.Copy(&sb, io.NewSectionReader(f, 0, f.Size())); err != nil {
		r.t.Fatal(err)
	}
	return sb.String(), true
}

func (r *rig) queued() int {
	names, _ := filepath.Glob(filepath.Join(r.staging, "q-*.json"))
	return len(names)
}

func TestCloseReturnsBeforeUploadAndFileStaysReadable(t *testing.T) {
	r := newRig(t)
	release := r.hold()
	r.write("/a.txt", "hello")
	if r.queued() != 1 {
		t.Fatal("upload not recorded on disk before it runs")
	}
	var st fuse.Stat_t
	if rc := r.fs.Getattr("/a.txt", &st, 0); rc != 0 || st.Size != 5 {
		t.Fatalf("getattr while uploading: %d size %d", rc, st.Size)
	}
	if got := r.read("/a.txt"); got != "hello" {
		t.Fatalf("read while uploading: %q", got)
	}
	release()
	r.idle()
	if got, ok := r.stored("/a.txt"); !ok || got != "hello" {
		t.Fatalf("stored %q %v", got, ok)
	}
	if r.queued() != 0 {
		t.Fatal("queue record left after upload")
	}
}

// Editors write a temporary file and rename it over the original.
func TestRenameWhileUploading(t *testing.T) {
	r := newRig(t)
	r.write("/doc.txt", "v1")
	r.idle()
	release := r.hold()
	r.write("/doc.txt.tmp", "v2")
	if rc := r.fs.Rename("/doc.txt.tmp", "/doc.txt"); rc != 0 {
		t.Fatalf("rename: %d", rc)
	}
	if got := r.read("/doc.txt"); got != "v2" {
		t.Fatalf("read after rename: %q", got)
	}
	// Saving again replaces the upload still running.
	r.write("/doc.txt.tmp", "v3")
	done := make(chan int, 1)
	go func() { done <- r.fs.Rename("/doc.txt.tmp", "/doc.txt") }()
	select {
	case rc := <-done:
		if rc != 0 {
			t.Fatalf("second rename: %d", rc)
		}
	case <-time.After(5 * time.Second):
		t.Fatal("second save waits for the first upload")
	}
	release()
	r.idle()
	if got, _ := r.stored("/doc.txt"); got != "v3" {
		t.Fatalf("stored %q", got)
	}
	if _, ok := r.stored("/doc.txt.tmp"); ok {
		t.Fatal("temporary file recorded")
	}
	if r.queued() != 0 {
		t.Fatal("queue records left")
	}
}

func TestUnlinkWhileUploading(t *testing.T) {
	r := newRig(t)
	release := r.hold()
	r.write("/gone.txt", "x")
	if rc := r.fs.Unlink("/gone.txt"); rc != 0 {
		t.Fatalf("unlink: %d", rc)
	}
	var st fuse.Stat_t
	if rc := r.fs.Getattr("/gone.txt", &st, 0); rc != -fuse.ENOENT {
		t.Fatalf("getattr after unlink: %d", rc)
	}
	release()
	r.idle()
	if _, ok := r.stored("/gone.txt"); ok {
		t.Fatal("deleted file recorded")
	}
}

// A crash during the upload leaves the queue record: the next start
// uploads it.
func TestQueuedUploadSurvivesRestart(t *testing.T) {
	r := newRig(t)
	release := r.hold()
	r.write("/keep.txt", "edit")
	if r.queued() != 1 {
		t.Fatal("no queue record")
	}
	// Another process (after a crash) sees the record and the staging copy.
	q, _ := filepath.Glob(filepath.Join(r.staging, "q-*.json"))
	data, _ := os.ReadFile(q[0])
	copyDir := t.TempDir()
	staged := filepath.Join(copyDir, "w-copy")
	r.fs.mu.Lock()
	name := r.fs.uploading["/keep.txt"].f.Name()
	r.fs.mu.Unlock()
	content, _ := os.ReadFile(name)
	os.WriteFile(staged, content, 0o600)
	os.WriteFile(filepath.Join(copyDir, "q-x.json"), []byte(strings.Replace(string(data), name, staged, 1)), 0o600)
	release()
	r.idle()

	r2 := &rig{t: t, e: r.e, staging: copyDir}
	r2.fs = r2.newFS()
	if left := r2.fs.RetryQueued(); left != 0 {
		t.Fatalf("%d left", left)
	}
	if got, _ := r.stored("/keep.txt"); got != "edit" {
		t.Fatalf("stored %q", got)
	}
}
