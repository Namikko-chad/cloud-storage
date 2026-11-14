// Package lock gives "open for writing" locks without a server.
//
// A device that opens a file for writing writes a lease object to every
// storage, then lists the leases for that file there. It wins a storage
// when no other live lease is there, and holds the lock when it wins on a
// majority of storages; otherwise it removes its lease and reports who
// holds the file. Leases of all files share one folder, l/, named
// <file hash>.<device>-<nonce>, so taking a lock creates no folders. Leases expire unless renewed, so a
// device that vanished does not block the file forever.
//
// This is a best-effort lock: a device that is offline cannot see leases.
// The index turns edits made without the lock into conflict copies.
package lock

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	mrand "math/rand"
	"path"
	"strings"
	"sync"
	"time"

	"cloudsync/core/backend"
	"cloudsync/core/crypto"
)

// Lease is the content of a lease object.
type Lease struct {
	Device     string    `json:"device"`
	DeviceName string    `json:"device_name"`
	Nonce      string    `json:"nonce"`
	Created    time.Time `json:"created"`
	Expires    time.Time `json:"expires"`
}

func (l Lease) before(o Lease) bool {
	if !l.Created.Equal(o.Created) {
		return l.Created.Before(o.Created)
	}
	if l.Device != o.Device {
		return l.Device < o.Device
	}
	return l.Nonce < o.Nonce
}

// LockedError reports that another device holds the file.
type LockedError struct {
	Path   string
	Holder Lease
}

func (e *LockedError) Error() string {
	return fmt.Sprintf("%s is open on %s since %s", e.Path, e.Holder.DeviceName, e.Holder.Created.Format(time.RFC3339))
}

// ErrNoQuorum means too few storages answered to decide.
var ErrNoQuorum = errors.New("lock: too few storages reachable")

// Manager takes and renews locks for one device.
type Manager struct {
	device, deviceName string
	key                crypto.Key
	stores             []backend.Store
	TTL                time.Duration
	Now                func() time.Time
	OnLost             func(path string) // a held lock could not be renewed

	mu   sync.Mutex
	held map[string]*Lock
	stop chan struct{}
	done chan struct{}
}

// Lock is a held lock.
type Lock struct {
	m     *Manager
	Path  string
	lease Lease
	name  string
	refs  int

	lmu sync.Mutex // guards lease (renewals change its expiry)

	// wmu orders writes of the lease with its removal: a renewal must not
	// bring a released lease back.
	wmu      sync.Mutex
	released bool
	// pending counts first writes still running on slow storages after
	// the lock was decided; the lease is removed only after them.
	pending sync.WaitGroup
}

// NewManager returns a manager. Call Run to renew leases in the background.
func NewManager(device, deviceName string, master crypto.Key, stores []backend.Store) *Manager {
	return &Manager{
		device: device, deviceName: deviceName,
		key:    master.Derive("lock", nil),
		stores: stores,
		TTL:    2 * time.Minute,
		Now:    time.Now,
		held:   map[string]*Lock{},
	}
}

func (m *Manager) quorum() int { return len(m.stores)/2 + 1 }

// prefix is the start of the names of p's leases.
func (m *Manager) prefix(p string) string { return "l/" + m.key.Name([]byte(p)) + "." }

// backgroundTimeout bounds lease writes that go on after a decision.
const backgroundTimeout = 2 * time.Minute

// result is what one storage said during an attempt.
type result struct {
	answered bool    // the lease was written and the leases listed
	leases   []Lease // live leases of other devices / attempts
}

// Acquire locks p for this device. Nested calls on the same path share the
// lock; each needs its own Release.
//
// The device writes its lease everywhere, then lists each storage. It wins
// a storage when no other live lease is there. Winning a majority is safe:
// two devices cannot both see "only me" on a storage both wrote to, and two
// majorities always share a storage. On contention everybody backs off and
// retries after a random delay.
func (m *Manager) Acquire(ctx context.Context, p string) (*Lock, error) {
	m.mu.Lock()
	if l := m.held[p]; l != nil {
		l.refs++
		m.mu.Unlock()
		return l, nil
	}
	m.mu.Unlock()

	const attempts = 4
	for try := 0; ; try++ {
		l, holder, err := m.try(ctx, p)
		if err != nil || l != nil {
			return l, err
		}
		// Somebody else is there. An established holder will not go away
		// soon: report it. A fresh lease may be a contender: retry.
		established := m.Now().Sub(holder.Created) > 5*time.Second
		if established || try == attempts-1 {
			return nil, &LockedError{Path: p, Holder: holder}
		}
		select {
		case <-ctx.Done():
			return nil, ctx.Err()
		case <-time.After(time.Duration(50+mrand.Intn(250)) * time.Millisecond):
		}
	}
}

// try makes one attempt. It returns the lock, or the earliest other lease.
//
// Each storage gets the lease and is then listed on its own, so a slow
// storage does not hold up the others: the attempt is decided as soon as
// a majority is won (or cannot be won). Writes still running then go on
// in the background.
func (m *Manager) try(ctx context.Context, p string) (*Lock, Lease, error) {
	now := m.Now()
	nonce := crypto.RandomID(8)
	l := &Lock{
		m: m, Path: p, refs: 1,
		lease: Lease{Device: m.device, DeviceName: m.deviceName, Nonce: nonce, Created: now, Expires: now.Add(m.TTL)},
	}
	l.name = m.prefix(p) + m.device + "-" + nonce
	sealed, err := m.seal(l)
	if err != nil {
		return nil, Lease{}, err
	}
	bg, cancel := context.WithTimeout(context.WithoutCancel(ctx), backgroundTimeout)
	results := make(chan result, len(m.stores))
	for _, s := range m.stores {
		l.pending.Add(1)
		go func(s backend.Store) {
			defer l.pending.Done()
			if err := backend.PutNew(bg, s, l.name, sealed); err != nil {
				results <- result{}
				return
			}
			leases, ok := m.live(bg, s, p, l)
			var others []Lease
			for _, o := range leases {
				if o.Device != m.device || o.Nonce != nonce {
					others = append(others, o)
				}
			}
			results <- result{answered: ok, leases: others}
		}(s)
	}
	go func() { l.pending.Wait(); cancel() }()

	q := m.quorum()
	wins, answered, done := 0, 0, 0
	var holder Lease
	for done < len(m.stores) {
		var r result
		select {
		case r = <-results:
		case <-ctx.Done():
			m.release(context.WithoutCancel(ctx), l)
			return nil, Lease{}, ctx.Err()
		}
		done++
		if r.answered {
			answered++
			if len(r.leases) == 0 {
				wins++
			}
			for _, o := range r.leases {
				if holder.Device == "" || o.before(holder) {
					holder = o
				}
			}
		}
		if wins >= q {
			break
		}
		// Lost for sure, and enough storages answered to say who holds it.
		if wins+len(m.stores)-done < q && answered >= q && holder.Device != "" {
			break
		}
	}
	if wins >= q {
		m.mu.Lock()
		if other := m.held[p]; other != nil { // raced with ourselves
			other.refs++
			m.mu.Unlock()
			m.release(ctx, l)
			return other, Lease{}, nil
		}
		m.held[p] = l
		m.mu.Unlock()
		return l, Lease{}, nil
	}
	m.release(context.WithoutCancel(ctx), l)
	if answered < q || holder.Device == "" {
		return nil, Lease{}, ErrNoQuorum
	}
	return nil, holder, nil
}

// Holder returns the lease that currently holds p, if any: the earliest
// live lease seen on a majority of storages.
func (m *Manager) Holder(ctx context.Context, p string) (*Lease, error) {
	votes := map[string]int{}
	leases := map[string]Lease{}
	answered := 0
	var mu sync.Mutex
	backend.Each(m.stores, func(s backend.Store) {
		list, ok := m.live(ctx, s, p, nil)
		if !ok {
			return
		}
		mu.Lock()
		defer mu.Unlock()
		answered++
		for _, l := range list {
			k := l.Device + "-" + l.Nonce
			votes[k]++
			leases[k] = l
		}
	})
	if answered < m.quorum() {
		return nil, ErrNoQuorum
	}
	var best *Lease
	for k, v := range votes {
		if l := leases[k]; v >= m.quorum() && (best == nil || l.before(*best)) {
			best = &l
		}
	}
	return best, nil
}

// Locked returns the holders of those of paths that are locked. It lists
// the lease folders once and asks the quorum only for paths that have one,
// so it is cheap enough for a directory listing.
func (m *Manager) Locked(ctx context.Context, paths []string) map[string]*Lease {
	has := map[string]bool{}
	for _, s := range backend.Fastest(m.stores) {
		names, err := s.List(ctx, "l")
		if err != nil {
			continue
		}
		for _, n := range names {
			has[path.Base(n)[:max(strings.IndexByte(path.Base(n), '.'), 0)]] = true
		}
		break
	}
	out := map[string]*Lease{}
	if len(has) == 0 {
		return out
	}
	for _, p := range paths {
		if !has[m.key.Name([]byte(p))] {
			continue
		}
		if h, err := m.Holder(ctx, p); err == nil && h != nil {
			out[p] = h
		}
	}
	return out
}

// Release drops one reference; the last one removes the lease.
func (l *Lock) Release(ctx context.Context) error {
	m := l.m
	m.mu.Lock()
	l.refs--
	if l.refs > 0 {
		m.mu.Unlock()
		return nil
	}
	if m.held[l.Path] == l {
		delete(m.held, l.Path)
	}
	m.mu.Unlock()
	m.release(ctx, l)
	return nil
}

// Held reports whether this device holds p.
func (m *Manager) Held(p string) bool {
	m.mu.Lock()
	defer m.mu.Unlock()
	return m.held[p] != nil
}

// Run renews held leases every TTL/3 until Close.
func (m *Manager) Run() {
	m.mu.Lock()
	if m.stop != nil {
		m.mu.Unlock()
		return
	}
	stop, done := make(chan struct{}), make(chan struct{})
	m.stop, m.done = stop, done
	m.mu.Unlock()
	go func() {
		defer close(done)
		t := time.NewTicker(m.TTL / 3)
		defer t.Stop()
		for {
			select {
			case <-stop:
				return
			case <-t.C:
				m.Renew(context.Background())
			}
		}
	}()
}

// Renew extends every held lease now.
func (m *Manager) Renew(ctx context.Context) {
	m.mu.Lock()
	locks := make([]*Lock, 0, len(m.held))
	for _, l := range m.held {
		locks = append(locks, l)
	}
	m.mu.Unlock()
	for _, l := range locks {
		if n, ok := m.renew(ctx, l); ok && n < m.quorum() && m.OnLost != nil {
			m.OnLost(l.Path)
		}
	}
}

// Close stops renewal and releases every lock.
func (m *Manager) Close(ctx context.Context) {
	m.mu.Lock()
	stop, done := m.stop, m.done
	m.stop, m.done = nil, nil
	held := m.held
	m.held = map[string]*Lock{}
	m.mu.Unlock()
	if stop != nil {
		close(stop)
		<-done
	}
	for _, l := range held {
		m.release(ctx, l)
	}
}

func (l *Lock) current() Lease {
	l.lmu.Lock()
	defer l.lmu.Unlock()
	return l.lease
}

func (m *Manager) seal(l *Lock) ([]byte, error) {
	plain, err := json.Marshal(l.current())
	if err != nil {
		return nil, err
	}
	return crypto.Seal(m.key, plain, []byte(l.name))
}

// renew writes l with a new expiry everywhere. ok is false when l was
// released meanwhile (nothing written).
func (m *Manager) renew(ctx context.Context, l *Lock) (int, bool) {
	l.wmu.Lock()
	defer l.wmu.Unlock()
	if l.released {
		return 0, false
	}
	l.lmu.Lock()
	l.lease.Expires = m.Now().Add(m.TTL)
	l.lmu.Unlock()
	sealed, err := m.seal(l)
	if err != nil {
		return 0, true
	}
	var mu sync.Mutex
	ok := 0
	backend.Each(m.stores, func(s backend.Store) {
		if s.Put(ctx, l.name, sealed) == nil {
			mu.Lock()
			ok++
			mu.Unlock()
		}
	})
	return ok, true
}

// release removes l's lease from every storage, after its first writes.
func (m *Manager) release(ctx context.Context, l *Lock) {
	l.pending.Wait()
	l.wmu.Lock()
	defer l.wmu.Unlock()
	l.released = true
	backend.Each(m.stores, func(s backend.Store) { _ = s.Delete(ctx, l.name) })
}

// live returns the live leases for p on s. Leases expired long ago are
// deleted on the way, and so are leases of this device that this process
// does not hold (left by a crash: only one process per device runs, see the
// engine's data dir lock). attempt is the lock being acquired right now
// (nil if none). Leases this process wrote are not downloaded.
func (m *Manager) live(ctx context.Context, s backend.Store, p string, attempt *Lock) ([]Lease, bool) {
	known := map[string]Lease{}
	m.mu.Lock()
	if h := m.held[p]; h != nil {
		known[h.name] = h.current()
	}
	m.mu.Unlock()
	if attempt != nil {
		known[attempt.name] = attempt.current()
	}
	names, err := s.List(ctx, "l")
	if err != nil {
		return nil, false
	}
	now := m.Now()
	var out []Lease
	prefix := m.prefix(p)
	for _, n := range names {
		if !strings.HasPrefix(n, prefix) {
			continue
		}
		if l, ok := known[n]; ok {
			if l.Expires.After(now) {
				out = append(out, l)
			}
			continue
		}
		data, err := s.Get(ctx, n)
		if err != nil {
			continue
		}
		plain, err := crypto.Open(m.key, data, []byte(n))
		if err != nil {
			continue
		}
		var l Lease
		if json.Unmarshal(plain, &l) != nil || !strings.HasPrefix(strings.TrimPrefix(n, prefix), l.Device+"-") {
			continue
		}
		if l.Device == m.device {
			_ = s.Delete(ctx, n) // our own stale lease
			continue
		}
		if !l.Expires.After(now) {
			if now.Sub(l.Expires) > m.TTL {
				_ = s.Delete(ctx, n)
			}
			continue
		}
		out = append(out, l)
	}
	return out, true
}
