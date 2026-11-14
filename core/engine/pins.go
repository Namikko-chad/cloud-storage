package engine

import (
	"context"
	"encoding/json"
	"errors"
	"os"
	"sort"
	"strings"
	"sync"

	"cloudsync/core/backend"
	"cloudsync/core/blob"
	"cloudsync/core/index"
)

// pins are the paths this device keeps fully local. A pinned directory
// covers everything below it, including files added later. Pinning "/"
// is the full local copy. Pins are per device and never synced.
type pins struct {
	file string
	mu   sync.Mutex
	set  map[string]bool
}

func loadPins(file string) (*pins, error) {
	p := &pins{file: file, set: map[string]bool{}}
	data, err := os.ReadFile(file)
	if errors.Is(err, os.ErrNotExist) {
		return p, nil
	}
	if err != nil {
		return nil, err
	}
	var list []string
	if err := json.Unmarshal(data, &list); err != nil {
		return nil, err
	}
	for _, s := range list {
		p.set[s] = true
	}
	return p, nil
}

func (p *pins) save() error {
	data, _ := json.Marshal(p.list())
	return writeFileAtomic(p.file, data)
}

func (p *pins) list() []string {
	out := make([]string, 0, len(p.set))
	for s := range p.set {
		out = append(out, s)
	}
	sort.Strings(out)
	return out
}

func (p *pins) covers(path string) bool {
	p.mu.Lock()
	defer p.mu.Unlock()
	for s := range p.set {
		if s == "/" || path == s || strings.HasPrefix(path, s+"/") {
			return true
		}
	}
	return false
}

// Pin keeps p (a file or a directory tree) local and downloads it now.
func (e *Engine) Pin(ctx context.Context, p string) error {
	p = index.Clean(p)
	if _, err := e.Stat(p); err != nil {
		return err
	}
	e.pins.mu.Lock()
	e.pins.set[p] = true
	err := e.pins.save()
	e.pins.mu.Unlock()
	if err != nil {
		return err
	}
	_, err = e.EnsurePinned(ctx)
	return err
}

// Unpin lets the cache drop p again.
func (e *Engine) Unpin(p string) error {
	p = index.Clean(p)
	e.pins.mu.Lock()
	defer e.pins.mu.Unlock()
	delete(e.pins.set, p)
	return e.pins.save()
}

// Pins returns the pinned paths.
func (e *Engine) Pins() []string {
	e.pins.mu.Lock()
	defer e.pins.mu.Unlock()
	return e.pins.list()
}

// IsPinned reports whether p is kept local.
func (e *Engine) IsPinned(p string) bool { return e.pins.covers(index.Clean(p)) }

// IsLocal reports whether the whole content of file p is on this device.
func (e *Engine) IsLocal(p string) bool {
	en, ok := e.idx.Get(p)
	if !ok || en.Version == nil {
		return false
	}
	for _, c := range en.Version.Chunks {
		if !e.cache.has(c.Blob.ID.String()) {
			return false
		}
	}
	return true
}

func (e *Engine) keepPinned() map[string]bool {
	keep := map[string]bool{}
	for id := range e.pinnedBlobs() {
		keep[id] = true
	}
	return keep
}

func (e *Engine) pinnedBlobs() map[string]blob.Ref {
	out := map[string]blob.Ref{}
	e.idx.Walk(func(en index.Entry) {
		if en.Version == nil || !e.pins.covers(en.Path) {
			return
		}
		for _, c := range en.Version.Chunks {
			out[c.Blob.ID.String()] = c.Blob
		}
	})
	return out
}

// EnsurePinned downloads every missing blob of pinned files and returns
// how many it fetched.
func (e *Engine) EnsurePinned(ctx context.Context) (int, error) {
	var todo []blob.Ref
	for id, ref := range e.pinnedBlobs() {
		if !e.cache.has(id) {
			todo = append(todo, ref)
		}
	}
	var mu sync.Mutex
	fetched := 0
	var errs []error
	backend.Limit(len(todo), pinParallel, func(i int) {
		_, err := e.blobData(ctx, todo[i])
		mu.Lock()
		defer mu.Unlock()
		if err != nil {
			errs = append(errs, err)
			return
		}
		fetched++
	})
	return fetched, errors.Join(errs...)
}

// pinParallel is how many blobs of pinned files download at the same time.
const pinParallel = 4
