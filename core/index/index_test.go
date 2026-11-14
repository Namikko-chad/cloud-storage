package index

import (
	"context"
	"fmt"
	"math/rand"
	"strings"
	"testing"
	"time"

	"cloudsync/core/backend"
	"cloudsync/core/crypto"
)

// device simulates one device producing ops.
type device struct {
	id  string
	seq uint64
	x   *Index
}

func (d *device) op(kind Kind, p string, size int64) Op {
	d.seq++
	parent := ""
	if e, ok := d.x.Get(p); ok {
		parent = e.VersionID
	}
	o := Op{Device: d.id, DeviceName: d.id, Seq: d.seq, Lamport: d.x.Lamport() + 1, Time: time.Unix(1700000000, 0), Kind: kind, Path: p, Parent: parent}
	if kind == OpPut {
		o.Version = &Version{Size: size}
	}
	d.x.Add(o)
	return o
}

func tree(x *Index) string {
	var b strings.Builder
	x.Walk(func(e Entry) {
		if e.Dir {
			fmt.Fprintf(&b, "%s/ ", e.Path)
		} else {
			fmt.Fprintf(&b, "%s=%d ", e.Path, e.Version.Size)
		}
	})
	return b.String()
}

func TestSequentialEdits(t *testing.T) {
	a := &device{id: "A", x: New()}
	b := &device{id: "B", x: New()}
	o1 := a.op(OpPut, "/docs/a.txt", 1)
	b.x.Add(o1)
	o2 := b.op(OpPut, "/docs/a.txt", 2) // B saw A's version: a normal edit
	a.x.Add(o2)
	if got := tree(a.x); got != "/docs/ /docs/a.txt=2 " {
		t.Fatal(got)
	}
	o3 := a.op(OpDelete, "/docs/a.txt", 0)
	b.x.Add(o3)
	if tree(a.x) != tree(b.x) || tree(b.x) != "/docs/ " {
		t.Fatal(tree(b.x))
	}
}

func TestConcurrentEditsMakeConflictCopy(t *testing.T) {
	a := &device{id: "A", x: New()}
	b := &device{id: "B", x: New()}
	base := a.op(OpPut, "/f.txt", 1)
	b.x.Add(base)
	ea := a.op(OpPut, "/f.txt", 10) // both edit without seeing each other
	eb := b.op(OpPut, "/f.txt", 20)
	a.x.Add(eb)
	b.x.Add(ea)
	if tree(a.x) != tree(b.x) {
		t.Fatalf("diverged:\n%s\n%s", tree(a.x), tree(b.x))
	}
	got := tree(a.x)
	if !strings.Contains(got, "/f.txt=10 ") || !strings.Contains(got, "/f (conflict B 2023-11-14 221320).txt=20") {
		t.Fatal(got)
	}
}

func TestDeleteLosesToConcurrentEdit(t *testing.T) {
	a := &device{id: "A", x: New()}
	b := &device{id: "B", x: New()}
	base := a.op(OpPut, "/f", 1)
	b.x.Add(base)
	del := a.op(OpDelete, "/f", 0)
	edit := b.op(OpPut, "/f", 5)
	a.x.Add(edit)
	b.x.Add(del)
	if tree(a.x) != "/f=5 " || tree(b.x) != "/f=5 " {
		t.Fatal(tree(a.x), tree(b.x))
	}
}

// Same ops in any order give the same tree.
func TestOrderIndependence(t *testing.T) {
	devs := []*device{{id: "A", x: New()}, {id: "B", x: New()}, {id: "C", x: New()}}
	r := rand.New(rand.NewSource(7))
	var all []Op
	paths := []string{"/a", "/b", "/d/c", "/d/e/f"}
	for i := 0; i < 300; i++ {
		d := devs[r.Intn(len(devs))]
		kind := OpPut
		if r.Intn(4) == 0 {
			kind = OpDelete
		}
		o := d.op(kind, paths[r.Intn(len(paths))], int64(i))
		all = append(all, o)
		// Gossip randomly, so devices often act on stale state.
		if r.Intn(3) == 0 {
			other := devs[r.Intn(len(devs))]
			other.x.Add(all[r.Intn(len(all)):]...)
		}
	}
	want := ""
	for i := 0; i < 5; i++ {
		x := New()
		perm := r.Perm(len(all))
		for _, p := range perm {
			x.Add(all[p])
		}
		got := tree(x)
		if i == 0 {
			want = got
		} else if got != want {
			t.Fatalf("order matters:\n%s\n%s", want, got)
		}
	}
	for _, d := range devs {
		d.x.Add(all...)
		if tree(d.x) != want {
			t.Fatalf("device %s differs", d.id)
		}
	}
}

func TestJournal(t *testing.T) {
	ctx := context.Background()
	key, _ := crypto.NewKey()
	m := []*backend.MemStore{backend.NewMemStore("s1"), backend.NewMemStore("s2"), backend.NewMemStore("s3")}
	stores := []backend.Store{m[0], m[1], m[2]}
	ja := NewJournal("A", key, stores, 2)
	jb := NewJournal("B", key, stores, 2)

	a := &device{id: "A", x: New()}
	if err := ja.Append(ctx, []Op{a.op(OpPut, "/x", 1), a.op(OpPut, "/y", 2)}); err != nil {
		t.Fatal(err)
	}
	m[2].SetOffline(true)
	if err := ja.Append(ctx, []Op{a.op(OpPut, "/z", 3)}); err != nil {
		t.Fatal("write with one storage down:", err)
	}
	m[1].SetOffline(true)
	if err := ja.Append(ctx, []Op{a.op(OpPut, "/w", 4)}); err == nil {
		t.Fatal("segment accepted with a single copy")
	}
	m[1].SetOffline(false)
	m[2].SetOffline(false)

	// The failed segment left one copy on s1: it may be read, and the
	// retry in a new segment carries the same op ids.
	ops, err := jb.Pull(ctx)
	if err != nil || len(ops) != 4 {
		t.Fatalf("pull: %d %v", len(ops), err)
	}
	if again, _ := jb.Pull(ctx); len(again) != 0 {
		t.Fatal("segments read twice")
	}
	if n, err := ja.Replicate(ctx); err != nil || n != 3 {
		t.Fatalf("replicate: %d %v", n, err)
	}
	for name, obj := range m[0].Objects() {
		if strings.Contains(string(obj), "/x") {
			t.Fatalf("plaintext path in %s", name)
		}
	}
	// A restarted device continues its numbering.
	ja2 := NewJournal("A", key, stores, 2)
	if err := ja2.Append(ctx, []Op{a.op(OpPut, "/v", 5)}); err != nil {
		t.Fatal(err)
	}
	if got, _ := jb.Pull(ctx); len(got) != 1 || got[0].Path != "/v" {
		t.Fatalf("%v", got)
	}
}

func TestCompact(t *testing.T) {
	ctx := context.Background()
	key, _ := crypto.NewKey()
	m := []*backend.MemStore{backend.NewMemStore("s1"), backend.NewMemStore("s2"), backend.NewMemStore("s3")}
	stores := []backend.Store{m[0], m[1], m[2]}
	ja := NewJournal("A", key, stores, 2)
	a := &device{id: "A", x: New()}
	for i := 0; i < 10; i++ {
		if err := ja.Append(ctx, []Op{a.op(OpPut, fmt.Sprintf("/f%d", i), int64(i+1))}); err != nil {
			t.Fatal(err)
		}
	}
	if n, _ := ja.Compact(ctx, 20, false); n != 0 {
		t.Fatal("packed below the threshold")
	}
	m[2].SetOffline(true) // misses the compaction
	if n, err := ja.Compact(ctx, 5, false); err != nil || n != 1 {
		t.Fatalf("compact: %d %v", n, err)
	}
	m[2].SetOffline(false)
	objs := 0
	for name := range m[0].Objects() {
		if strings.HasPrefix(name, "j/A/") {
			objs++
		}
	}
	if objs != 1 {
		t.Fatalf("%d journal objects after compaction, want 1", objs)
	}
	counts := ja.Counts(ctx)
	if counts["s1"] != 10 || counts["s3"] != 10 {
		t.Fatalf("coverage %v", counts)
	}
	// New segments continue after the pack, also in a new process.
	ja2 := NewJournal("A", key, stores, 2)
	if err := ja2.Append(ctx, []Op{a.op(OpPut, "/g", 11)}); err != nil {
		t.Fatal(err)
	}
	jb := NewJournal("B", key, stores, 2)
	ops, err := jb.Pull(ctx)
	if err != nil {
		t.Fatal(err)
	}
	x := New()
	x.Add(ops...)
	if len(x.List("/")) != 11 {
		t.Fatalf("tree after pull of packed journal: %d entries", len(x.List("/")))
	}
	// Replicate brings the pack to s3, and the next compaction cleans it.
	if _, err := ja.Replicate(ctx); err != nil {
		t.Fatal(err)
	}
	ja2.Pull(ctx)
	if _, err := ja2.Compact(ctx, 5, true); err != nil {
		t.Fatal(err)
	}
	left := 0
	for name := range m[2].Objects() {
		if strings.HasPrefix(name, "j/A/0") {
			left++
		}
	}
	if left != 1 { // only the segment after the pack
		t.Fatalf("%d loose segments on s3", left)
	}
}

// Counts right after a Pull answers from that Pull's listing (no second
// listing of slow storages) and follows this device's own appends.
func TestCountsFromPull(t *testing.T) {
	ctx := context.Background()
	key, _ := crypto.NewKey()
	m := []*backend.MemStore{backend.NewMemStore("s1"), backend.NewMemStore("s2"), backend.NewMemStore("s3")}
	stores := []backend.Store{m[0], m[1], m[2]}
	ja := NewJournal("A", key, stores, 2)
	a := &device{id: "A", x: New()}
	for i := 0; i < 3; i++ {
		if err := ja.Append(ctx, []Op{a.op(OpPut, fmt.Sprintf("/f%d", i), 1)}); err != nil {
			t.Fatal(err)
		}
	}
	m[2].SetOffline(true)
	jb := NewJournal("B", key, stores, 2)
	if _, err := jb.Pull(ctx); err != nil {
		t.Fatal(err)
	}
	m[2].SetOffline(false)
	m[1].SetOffline(true) // would fail a listing: the cached counts are used
	c := jb.Counts(ctx)
	if len(c) != 2 || c["s1"] != 3 || c["s2"] != 3 {
		t.Fatalf("counts after pull %v", c)
	}
	m[1].SetOffline(false)
	if err := jb.Append(ctx, []Op{a.op(OpPut, "/g", 1)}); err != nil {
		t.Fatal(err)
	}
	if c := jb.Counts(ctx); c["s1"] != 4 || c["s2"] != 4 {
		t.Fatalf("counts after append %v", c)
	}
	if _, err := jb.Replicate(ctx); err != nil {
		t.Fatal(err)
	}
	if c := jb.Counts(ctx); c["s1"] != 4 || c["s3"] != 4 {
		t.Fatalf("counts after replicate %v", c)
	}
}

// hookStore runs hook before its first listing of a device directory.
type hookStore struct {
	*backend.MemStore
	hook func()
}

func (h *hookStore) List(ctx context.Context, dir string) ([]string, error) {
	if h.hook != nil {
		f := h.hook
		h.hook = nil
		f()
	}
	return h.MemStore.List(ctx, dir)
}

// A segment written while Pull lists storages one by one must not make the
// storages listed before it look behind.
func TestCountsSkipListingDuringAppend(t *testing.T) {
	ctx := context.Background()
	key, _ := crypto.NewKey()
	m := []*backend.MemStore{backend.NewMemStore("s1"), backend.NewMemStore("s2"), backend.NewMemStore("s3")}
	last := &hookStore{MemStore: m[2]}
	stores := []backend.Store{m[0], m[1], last}
	ja := NewJournal("A", key, stores, 2)
	a := &device{id: "A", x: New()}
	if err := ja.Append(ctx, []Op{a.op(OpPut, "/f", 1)}); err != nil {
		t.Fatal(err)
	}
	last.hook = func() {
		if err := ja.Append(ctx, []Op{a.op(OpPut, "/g", 1)}); err != nil {
			t.Error(err)
		}
	}
	if _, err := ja.Pull(ctx); err != nil {
		t.Fatal(err)
	}
	if c := ja.Counts(ctx); c["s1"] != 2 || c["s2"] != 2 || c["s3"] != 2 {
		t.Fatalf("counts %v: a storage looks behind", c)
	}
}

// Duplicate names (Drive and Mega allow them) and overlapping packs count
// each segment once, or a storage with duplicates makes the others look behind.
func TestCoverageCountsDistinct(t *testing.T) {
	names := []string{
		segName("A", 1), segName("A", 2), segName("A", 2),
		packName("A", seqRange{3, 5}), packName("A", seqRange{3, 5}), packName("A", seqRange{4, 6}),
		segName("A", 4), segName("A", 9),
	}
	if n := coverage(names); n != 7 { // 1..6 and 9
		t.Fatalf("coverage %d, want 7", n)
	}
	if n := coverage(nil); n != 0 {
		t.Fatalf("coverage of nothing %d", n)
	}
}
