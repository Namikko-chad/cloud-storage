// Package index keeps the file tree without a server. Every device appends
// operations to its own journal; the tree is a pure function of the set of
// all operations, folded in a total order (Lamport clock, device, seq), so
// every device that has seen the same operations sees the same tree.
//
// Concurrent edits (two puts based on the same parent version) do not
// overwrite each other: the later one in the total order is kept as a
// conflict copy next to the file.
package index

import (
	"fmt"
	"path"
	"sort"
	"strings"
	"sync"
	"time"

	"cloudsync/core/blob"
)

// Kind of operation.
type Kind string

const (
	OpPut    Kind = "put"    // create or replace a file
	OpDelete Kind = "delete" // remove a file or an empty dir
	OpMkdir  Kind = "mkdir"
	OpPlace  Kind = "place" // blobs moved to other storages (repair)
)

// Op is one change, made by one device.
type Op struct {
	Device string `json:"device"`
	// DeviceName goes into conflict copy names. It is in the op (not looked
	// up) so that every device derives the same names.
	DeviceName string    `json:"device_name,omitempty"`
	Seq        uint64    `json:"seq"` // per device, starts at 1
	Lamport    uint64    `json:"lamport"`
	Time       time.Time `json:"time"`
	Kind       Kind      `json:"kind"`
	Path       string    `json:"path"`
	// Parent is the version id the device had for Path when it made the
	// change ("" if it had none). It is what detects concurrent edits.
	Parent  string   `json:"parent,omitempty"`
	Version *Version `json:"version,omitempty"` // for OpPut
	// Places maps blob id (hex) to its new placement, for OpPlace.
	Places map[string][]string `json:"places,omitempty"`
	// Refs maps blob id (hex) to a new ref (encoded again with another
	// k/m), for OpPlace. Applied before Places of the same op.
	Refs map[string]blob.Ref `json:"refs,omitempty"`
	// Secret is the sealed safe record of an OpSecret (see secrets.go).
	Secret *SecretChange `json:"secret,omitempty"`
}

// ID identifies the op and the version it creates.
func (o Op) ID() string { return fmt.Sprintf("%s.%d", o.Device, o.Seq) }

func (o Op) less(p Op) bool {
	if o.Lamport != p.Lamport {
		return o.Lamport < p.Lamport
	}
	if o.Device != p.Device {
		return o.Device < p.Device
	}
	return o.Seq < p.Seq
}

// Version is the content of a file at one point.
type Version struct {
	Size    int64      `json:"size"`
	ModTime time.Time  `json:"mtime"`
	Mode    uint32     `json:"mode,omitempty"`
	Hash    blob.HexID `json:"hash"` // keyed hash of the whole content
	Chunks  []Chunk    `json:"chunks"`
}

// Chunk is a piece of a file: a byte range of a blob. Small files share
// one blob (a pack); big files have one blob per chunk.
type Chunk struct {
	Blob   blob.Ref `json:"blob"`
	Offset int      `json:"off,omitempty"`
	Length int      `json:"len"`
}

// Entry is a node of the tree.
type Entry struct {
	Path      string
	Dir       bool
	VersionID string // op id that created the current content
	Version   *Version
	Device    string // who made the current version
	Time      time.Time
	// ConflictOf is set on a conflict copy: the path it collided with.
	ConflictOf string
}

// Name is the last path element.
func (e Entry) Name() string { return path.Base(e.Path) }

// Clean normalizes a path: rooted, slash separated, no trailing slash.
func Clean(p string) string {
	return path.Clean("/" + strings.ReplaceAll(p, "\\", "/"))
}

// Index is the merged tree. It is safe for concurrent use.
type Index struct {
	mu      sync.RWMutex
	ops     map[string]Op
	order   []Op // sorted
	entries map[string]*Entry
	lamport uint64
	over    map[string]override // blob id → newer location than the one in refs
	secrets map[string]*Secret  // password safe records by id
}

type override struct {
	ref   *blob.Ref
	place []string
}

// New returns an empty index.
func New() *Index {
	return &Index{ops: map[string]Op{}, entries: map[string]*Entry{}, over: map[string]override{}, secrets: map[string]*Secret{}}
}

// Lamport returns the highest Lamport time seen.
func (x *Index) Lamport() uint64 {
	x.mu.RLock()
	defer x.mu.RUnlock()
	return x.lamport
}

// Len returns the number of known ops; it grows when anything changes.
func (x *Index) Len() int {
	x.mu.RLock()
	defer x.mu.RUnlock()
	return len(x.ops)
}

// Has reports whether op id is known.
func (x *Index) Has(id string) bool {
	x.mu.RLock()
	defer x.mu.RUnlock()
	_, ok := x.ops[id]
	return ok
}

// Add merges ops (unknown ones only) and reports whether the tree may have
// changed.
func (x *Index) Add(ops ...Op) bool {
	x.mu.Lock()
	defer x.mu.Unlock()
	var fresh []Op
	for _, o := range ops {
		o.Path = Clean(o.Path)
		if _, ok := x.ops[o.ID()]; ok {
			continue
		}
		x.ops[o.ID()] = o
		fresh = append(fresh, o)
		if o.Lamport > x.lamport {
			x.lamport = o.Lamport
		}
	}
	if len(fresh) == 0 {
		return false
	}
	sort.Slice(fresh, func(i, j int) bool { return fresh[i].less(fresh[j]) })
	if len(x.order) == 0 || x.order[len(x.order)-1].less(fresh[0]) {
		// Common case: everything new comes after what we have.
		for _, o := range fresh {
			x.apply(o)
		}
		x.order = append(x.order, fresh...)
		return true
	}
	// An op from the past (a device was offline): refold everything.
	x.order = append(x.order, fresh...)
	sort.Slice(x.order, func(i, j int) bool { return x.order[i].less(x.order[j]) })
	x.entries = map[string]*Entry{}
	x.over = map[string]override{}
	x.secrets = map[string]*Secret{}
	for _, o := range x.order {
		x.apply(o)
	}
	return true
}

func (x *Index) apply(o Op) {
	if o.Kind == OpSecret {
		x.applySecret(o)
		return
	}
	cur := x.entries[o.Path]
	head := ""
	if cur != nil {
		head = cur.VersionID
	}
	switch o.Kind {
	case OpPlace:
		for id, r := range o.Refs {
			r := r
			x.over[id] = override{ref: &r}
		}
		for id, p := range o.Places {
			ov := x.over[id]
			ov.place = p
			x.over[id] = ov
		}
	case OpMkdir:
		if cur == nil {
			x.mkdirAll(o.Path, o)
		}
	case OpDelete:
		if cur == nil || head != o.Parent {
			return // changed meanwhile by someone else: the change wins
		}
		if cur.Dir && x.hasChildren(o.Path) {
			return
		}
		delete(x.entries, o.Path)
	case OpPut:
		if o.Version == nil {
			return
		}
		target := o.Path
		if cur != nil && (cur.Dir || head != o.Parent) {
			target = x.conflictPath(o)
		}
		x.mkdirAll(path.Dir(target), o)
		en := &Entry{Path: target, VersionID: o.ID(), Version: o.Version, Device: o.Device, Time: o.Time}
		if target != o.Path {
			en.ConflictOf = o.Path
		}
		x.entries[target] = en
	}
}

func (x *Index) mkdirAll(p string, o Op) {
	for p != "/" {
		if e, ok := x.entries[p]; ok {
			if !e.Dir {
				return // a file is in the way; its children become conflicts
			}
		} else {
			x.entries[p] = &Entry{Path: p, Dir: true, VersionID: o.ID(), Device: o.Device, Time: o.Time}
		}
		p = path.Dir(p)
	}
}

func (x *Index) hasChildren(dir string) bool {
	prefix := dir + "/"
	for p := range x.entries {
		if strings.HasPrefix(p, prefix) {
			return true
		}
	}
	return false
}

func (x *Index) conflictPath(o Op) string {
	name := o.DeviceName
	if name == "" {
		name = o.Device
	}
	dir, base := path.Split(o.Path)
	ext := path.Ext(base)
	stem := strings.TrimSuffix(base, ext)
	p := fmt.Sprintf("%s%s (conflict %s %s)%s", dir, stem, name, o.Time.UTC().Format("2006-01-02 150405"), ext)
	for i := 2; x.entries[p] != nil; i++ {
		p = fmt.Sprintf("%s%s (conflict %s %s %d)%s", dir, stem, name, o.Time.UTC().Format("2006-01-02 150405"), i, ext)
	}
	return p
}

// Resolve returns ref with the latest location recorded for its blob.
func (x *Index) Resolve(ref blob.Ref) blob.Ref {
	x.mu.RLock()
	defer x.mu.RUnlock()
	ov, ok := x.over[ref.ID.String()]
	if !ok {
		return ref
	}
	if ov.ref != nil {
		ref = *ov.ref
		ref.Placement = append([]string{}, ref.Placement...)
	}
	if ov.place != nil {
		ref.Placement = append([]string{}, ov.place...)
		ref.Missing = nil
	}
	return ref
}

// Get returns the entry at p.
func (x *Index) Get(p string) (Entry, bool) {
	x.mu.RLock()
	defer x.mu.RUnlock()
	p = Clean(p)
	if p == "/" {
		return Entry{Path: "/", Dir: true}, true
	}
	e, ok := x.entries[p]
	if !ok {
		return Entry{}, false
	}
	return *e, true
}

// List returns the direct children of dir, sorted by name.
func (x *Index) List(dir string) []Entry {
	x.mu.RLock()
	defer x.mu.RUnlock()
	dir = Clean(dir)
	var out []Entry
	for p, e := range x.entries {
		if path.Dir(p) == dir && p != "/" {
			out = append(out, *e)
		}
	}
	sort.Slice(out, func(i, j int) bool { return out[i].Path < out[j].Path })
	return out
}

// Walk calls fn for every entry, in path order.
func (x *Index) Walk(fn func(Entry)) {
	x.mu.RLock()
	all := make([]Entry, 0, len(x.entries))
	for _, e := range x.entries {
		all = append(all, *e)
	}
	x.mu.RUnlock()
	sort.Slice(all, func(i, j int) bool { return all[i].Path < all[j].Path })
	for _, e := range all {
		fn(e)
	}
}

// Ops returns all known ops in fold order.
func (x *Index) Ops() []Op {
	x.mu.RLock()
	defer x.mu.RUnlock()
	return append([]Op{}, x.order...)
}
