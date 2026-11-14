package backend

import (
	"context"
	"errors"
	"sort"
	"sync"
	"time"
)

// NewPutter is a Store that can write an object it knows does not exist
// yet, skipping the lookup some providers do before a write.
type NewPutter interface {
	PutNew(ctx context.Context, name string, data []byte) error
}

// PutNew writes an object whose name was never used (journal segments,
// leases, packs). Do not use it for names that may exist: on Drive and
// Mega it would make a second object with the same name.
func PutNew(ctx context.Context, s Store, name string, data []byte) error {
	if p, ok := s.(NewPutter); ok {
		return p.PutNew(ctx, name, data)
	}
	return s.Put(ctx, name, data)
}

// Stats are the recent response times of a storage.
type Stats struct {
	// Smoothed duration of a call; 0 until the first one finished.
	Get, Put, List time.Duration
	Errors         int // failed calls in a row
}

// Score orders storages for reading: lower is faster. Unknown storages
// come between fast and slow ones, a failing one goes last.
func (s Stats) Score() time.Duration {
	d := s.Get
	if d == 0 {
		d = s.List
	}
	if d == 0 {
		d = time.Second
	}
	return d * time.Duration(1+min(s.Errors, 10))
}

// StatsOf returns the stats of s, or zero ones if s does not keep them.
func StatsOf(s Store) Stats {
	if m, ok := s.(interface{ Stats() Stats }); ok {
		return m.Stats()
	}
	return Stats{}
}

// DefaultParallel is how many calls one storage gets at the same time.
const DefaultParallel = 6

// Measured wraps s so that at most parallel calls run on it at once and
// their durations are kept (see StatsOf).
func Measured(s Store, parallel int) Store {
	if parallel < 1 {
		parallel = DefaultParallel
	}
	return &measured{Store: s, slots: make(chan struct{}, parallel)}
}

type measured struct {
	Store
	slots chan struct{}
	mu    sync.Mutex
	st    Stats
}

func (m *measured) Stats() Stats {
	m.mu.Lock()
	defer m.mu.Unlock()
	return m.st
}

// do runs call in a slot and records how long it took.
func (m *measured) do(ctx context.Context, kind *time.Duration, call func() error) error {
	select {
	case m.slots <- struct{}{}:
	case <-ctx.Done():
		return ctx.Err()
	}
	start := time.Now()
	err := call()
	took := time.Since(start)
	<-m.slots
	if errors.Is(err, context.Canceled) {
		return err // cancelled by us (a hedged read), says nothing
	}
	m.mu.Lock()
	defer m.mu.Unlock()
	if err != nil && !errors.Is(err, ErrNotFound) && !errors.Is(err, ErrNoUsage) {
		m.st.Errors++
		return err
	}
	m.st.Errors = 0
	if kind != nil {
		if *kind == 0 {
			*kind = took
		} else {
			*kind = (*kind*3 + took) / 4
		}
	}
	return err
}

func (m *measured) Put(ctx context.Context, name string, data []byte) error {
	return m.do(ctx, &m.st.Put, func() error { return m.Store.Put(ctx, name, data) })
}

func (m *measured) PutNew(ctx context.Context, name string, data []byte) error {
	return m.do(ctx, &m.st.Put, func() error { return PutNew(ctx, m.Store, name, data) })
}

func (m *measured) Get(ctx context.Context, name string) ([]byte, error) {
	var out []byte
	err := m.do(ctx, &m.st.Get, func() (err error) {
		out, err = m.Store.Get(ctx, name)
		return err
	})
	return out, err
}

func (m *measured) Delete(ctx context.Context, name string) error {
	return m.do(ctx, nil, func() error { return m.Store.Delete(ctx, name) })
}

func (m *measured) List(ctx context.Context, dir string) ([]string, error) {
	var out []string
	err := m.do(ctx, &m.st.List, func() (err error) {
		out, err = m.Store.List(ctx, dir)
		return err
	})
	return out, err
}

func (m *measured) ListDirs(ctx context.Context, dir string) ([]string, error) {
	var out []string
	err := m.do(ctx, &m.st.List, func() (err error) {
		out, err = m.Store.ListDirs(ctx, dir)
		return err
	})
	return out, err
}

func (m *measured) About(ctx context.Context) (Usage, error) {
	var u Usage
	err := m.do(ctx, nil, func() (err error) {
		u, err = About(ctx, m.Store)
		return err
	})
	return u, err
}

// Close closes the wrapped store if it can be closed.
func (m *measured) Close() error {
	if c, ok := m.Store.(interface{ Close() error }); ok {
		return c.Close()
	}
	return nil
}

// Each runs fn for every store at the same time and waits for all.
func Each(stores []Store, fn func(s Store)) {
	var wg sync.WaitGroup
	for _, s := range stores {
		wg.Add(1)
		go func() {
			defer wg.Done()
			fn(s)
		}()
	}
	wg.Wait()
}

// Limit runs fn(i) for i in [0, n) with at most parallel at a time.
func Limit(n, parallel int, fn func(i int)) {
	if parallel < 1 {
		parallel = 1
	}
	slots := make(chan struct{}, parallel)
	var wg sync.WaitGroup
	for i := range n {
		slots <- struct{}{}
		wg.Add(1)
		go func() {
			defer func() { <-slots; wg.Done() }()
			fn(i)
		}()
	}
	wg.Wait()
}

// Fastest returns stores ordered by their recent response time, fastest
// first (stable for storages without stats).
func Fastest(stores []Store) []Store {
	out := append([]Store(nil), stores...)
	score := make(map[Store]time.Duration, len(out))
	for _, s := range out {
		score[s] = StatsOf(s).Score()
	}
	sort.SliceStable(out, func(a, b int) bool { return score[out[a]] < score[out[b]] })
	return out
}
