// Package backend gives every storage account the same small object API.
// Objects are addressed by slash-separated names relative to the vault
// folder inside the account. Payloads are small (a shard, a journal
// segment, a lease), so the API works with whole byte slices.
package backend

import (
	"context"
	"errors"
	"sort"
	"strings"
	"sync"
)

// ErrNotFound is returned by Get for a missing object.
var ErrNotFound = errors.New("backend: object not found")

// ErrOffline is returned by MemStore while it simulates an outage.
var ErrOffline = errors.New("backend: offline")

// Store is one storage account.
type Store interface {
	// ID is the vault backend id (not the type: two Mega accounts differ).
	ID() string
	// Put creates or replaces an object.
	Put(ctx context.Context, name string, data []byte) error
	// Get returns ErrNotFound if the object does not exist.
	Get(ctx context.Context, name string) ([]byte, error)
	// Delete succeeds if the object does not exist.
	Delete(ctx context.Context, name string) error
	// List returns the full names of objects directly inside dir.
	// A missing dir is an empty list.
	List(ctx context.Context, dir string) ([]string, error)
	// ListDirs returns the full names of subdirectories directly inside dir.
	ListDirs(ctx context.Context, dir string) ([]string, error)
}

// ErrNoUsage is returned by About when a storage cannot report its space.
var ErrNoUsage = errors.New("backend: storage does not report its space")

// Usage is the space of a storage account in bytes. Free is what can still
// be written there (the quota left, or the disk's free space).
type Usage struct {
	Total, Used, Free int64
}

// Abouter is a Store that can report its space.
type Abouter interface {
	About(ctx context.Context) (Usage, error)
}

// About returns the space of s, or ErrNoUsage if s cannot tell.
func About(ctx context.Context, s Store) (Usage, error) {
	if a, ok := s.(Abouter); ok {
		return a.About(ctx)
	}
	return Usage{}, ErrNoUsage
}

// MemStore is an in-memory Store for tests. It can simulate an outage.
type MemStore struct {
	id      string
	mu      sync.Mutex
	objs    map[string][]byte
	offline bool
	// Quota > 0 makes About report it (Used is the sum of object sizes).
	Quota int64
	Puts  int
	Gets  int
}

// NewMemStore returns an empty MemStore.
func NewMemStore(id string) *MemStore {
	return &MemStore{id: id, objs: map[string][]byte{}}
}

func (m *MemStore) ID() string { return m.id }

// SetOffline makes every call fail with ErrOffline (or work again).
func (m *MemStore) SetOffline(off bool) {
	m.mu.Lock()
	m.offline = off
	m.mu.Unlock()
}

// Wipe deletes everything, like a lost account.
func (m *MemStore) Wipe() {
	m.mu.Lock()
	m.objs = map[string][]byte{}
	m.mu.Unlock()
}

// Objects returns a copy of all objects.
func (m *MemStore) Objects() map[string][]byte {
	m.mu.Lock()
	defer m.mu.Unlock()
	out := make(map[string][]byte, len(m.objs))
	for k, v := range m.objs {
		out[k] = append([]byte{}, v...)
	}
	return out
}

func (m *MemStore) check(ctx context.Context) error {
	if err := ctx.Err(); err != nil {
		return err
	}
	if m.offline {
		return ErrOffline
	}
	return nil
}

func (m *MemStore) About(ctx context.Context) (Usage, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	if err := m.check(ctx); err != nil {
		return Usage{}, err
	}
	if m.Quota <= 0 {
		return Usage{}, ErrNoUsage
	}
	var used int64
	for _, d := range m.objs {
		used += int64(len(d))
	}
	return Usage{Total: m.Quota, Used: used, Free: max(m.Quota-used, 0)}, nil
}

func (m *MemStore) Put(ctx context.Context, name string, data []byte) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	if err := m.check(ctx); err != nil {
		return err
	}
	m.Puts++
	m.objs[name] = append([]byte{}, data...)
	return nil
}

func (m *MemStore) Get(ctx context.Context, name string) ([]byte, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	if err := m.check(ctx); err != nil {
		return nil, err
	}
	m.Gets++
	d, ok := m.objs[name]
	if !ok {
		return nil, ErrNotFound
	}
	return append([]byte{}, d...), nil
}

func (m *MemStore) Delete(ctx context.Context, name string) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	if err := m.check(ctx); err != nil {
		return err
	}
	delete(m.objs, name)
	return nil
}

func (m *MemStore) List(ctx context.Context, dir string) ([]string, error) {
	return m.list(ctx, dir, false)
}

func (m *MemStore) ListDirs(ctx context.Context, dir string) ([]string, error) {
	return m.list(ctx, dir, true)
}

func (m *MemStore) list(ctx context.Context, dir string, dirs bool) ([]string, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	if err := m.check(ctx); err != nil {
		return nil, err
	}
	prefix := strings.TrimSuffix(dir, "/") + "/"
	if dir == "" {
		prefix = ""
	}
	seen := map[string]bool{}
	for name := range m.objs {
		rest, ok := strings.CutPrefix(name, prefix)
		if !ok {
			continue
		}
		i := strings.IndexByte(rest, '/')
		switch {
		case !dirs && i < 0:
			seen[name] = true
		case dirs && i >= 0:
			seen[prefix+rest[:i]] = true
		}
	}
	out := make([]string, 0, len(seen))
	for n := range seen {
		out = append(out, n)
	}
	sort.Strings(out)
	return out, nil
}
