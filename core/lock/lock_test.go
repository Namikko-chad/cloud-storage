package lock

import (
	"context"
	"errors"
	"sync"
	"testing"
	"time"

	"cloudsync/core/backend"
	"cloudsync/core/crypto"
)

type clock struct {
	mu sync.Mutex
	t  time.Time
}

func (c *clock) now() time.Time { c.mu.Lock(); defer c.mu.Unlock(); return c.t }
func (c *clock) add(d time.Duration) {
	c.mu.Lock()
	c.t = c.t.Add(d)
	c.mu.Unlock()
}

func setup() ([]*backend.MemStore, *Manager, *Manager, *clock) {
	key, _ := crypto.NewKey()
	mem := []*backend.MemStore{backend.NewMemStore("1"), backend.NewMemStore("2"), backend.NewMemStore("3")}
	stores := []backend.Store{mem[0], mem[1], mem[2]}
	c := &clock{t: time.Unix(1700000000, 0)}
	a := NewManager("A", "laptop", key, stores)
	b := NewManager("B", "phone", key, stores)
	a.Now, b.Now = c.now, c.now
	return mem, a, b, c
}

func TestExclusive(t *testing.T) {
	ctx := context.Background()
	_, a, b, _ := setup()
	la, err := a.Acquire(ctx, "/doc.txt")
	if err != nil {
		t.Fatal(err)
	}
	_, err = b.Acquire(ctx, "/doc.txt")
	var le *LockedError
	if !errors.As(err, &le) || le.Holder.DeviceName != "laptop" {
		t.Fatalf("B got lock: %v", err)
	}
	if _, err := b.Acquire(ctx, "/other.txt"); err != nil {
		t.Fatal("unrelated file locked:", err)
	}
	h, err := b.Holder(ctx, "/doc.txt")
	if err != nil || h == nil || h.Device != "A" {
		t.Fatalf("holder: %v %v", h, err)
	}
	la.Release(ctx)
	if _, err := b.Acquire(ctx, "/doc.txt"); err != nil {
		t.Fatal("not free after release:", err)
	}
}

func TestReentrant(t *testing.T) {
	ctx := context.Background()
	_, a, b, _ := setup()
	l1, _ := a.Acquire(ctx, "/f")
	l2, err := a.Acquire(ctx, "/f")
	if err != nil || l1 != l2 {
		t.Fatal("second open on same device failed")
	}
	l1.Release(ctx)
	if _, err := b.Acquire(ctx, "/f"); err == nil {
		t.Fatal("released while still open once")
	}
	l2.Release(ctx)
	if _, err := b.Acquire(ctx, "/f"); err != nil {
		t.Fatal(err)
	}
}

func TestExpiryAndRenewal(t *testing.T) {
	ctx := context.Background()
	_, a, b, c := setup()
	if _, err := a.Acquire(ctx, "/f"); err != nil {
		t.Fatal(err)
	}
	c.add(90 * time.Second)
	a.Renew(ctx)
	c.add(90 * time.Second)
	if _, err := b.Acquire(ctx, "/f"); err == nil {
		t.Fatal("renewed lease ignored")
	}
	c.add(3 * time.Minute) // A crashed: no renewal
	if _, err := b.Acquire(ctx, "/f"); err != nil {
		t.Fatal("expired lease still blocks:", err)
	}
}

func TestQuorum(t *testing.T) {
	ctx := context.Background()
	mem, a, b, _ := setup()
	mem[0].SetOffline(true)
	if _, err := a.Acquire(ctx, "/f"); err != nil {
		t.Fatal("2 of 3 storages should be enough:", err)
	}
	mem[0].SetOffline(false)
	mem[1].SetOffline(true)
	if _, err := b.Acquire(ctx, "/f"); err == nil {
		t.Fatal("B won: storage 1 has no lease of A but 3 does")
	}
	mem[2].SetOffline(true)
	if _, err := b.Acquire(ctx, "/g"); !errors.Is(err, ErrNoQuorum) {
		t.Fatalf("1 of 3 storages: %v", err)
	}
}

func TestRace(t *testing.T) {
	ctx := context.Background()
	key, _ := crypto.NewKey()
	stores := []backend.Store{backend.NewMemStore("1"), backend.NewMemStore("2"), backend.NewMemStore("3")}
	for round := 0; round < 20; round++ {
		var wg sync.WaitGroup
		var mu sync.Mutex
		winners := 0
		var locks []*Lock
		for _, id := range []string{"A", "B", "C", "D"} {
			m := NewManager(id, id, key, stores)
			wg.Add(1)
			go func() {
				defer wg.Done()
				if l, err := m.Acquire(ctx, "/race"); err == nil {
					mu.Lock()
					winners++
					locks = append(locks, l)
					mu.Unlock()
				}
			}()
		}
		wg.Wait()
		if winners > 1 {
			t.Fatalf("round %d: %d devices hold the lock", round, winners)
		}
		for _, l := range locks {
			l.Release(ctx)
		}
	}
}

// A device that crashed while holding a lock gets it back after restart;
// other devices still see it held until it expires.
func TestReclaimAfterCrash(t *testing.T) {
	ctx := context.Background()
	key, _ := crypto.NewKey()
	stores := []backend.Store{backend.NewMemStore("1"), backend.NewMemStore("2"), backend.NewMemStore("3")}
	crashed := NewManager("A", "laptop", key, stores)
	if _, err := crashed.Acquire(ctx, "/f"); err != nil {
		t.Fatal(err)
	}
	other := NewManager("B", "phone", key, stores)
	if _, err := other.Acquire(ctx, "/f"); err == nil {
		t.Fatal("phone took a held lock")
	}
	restarted := NewManager("A", "laptop", key, stores) // same device, new process
	if _, err := restarted.Acquire(ctx, "/f"); err != nil {
		t.Fatal("restarted device cannot reclaim its lock:", err)
	}
}
