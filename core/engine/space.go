package engine

import (
	"context"
	"encoding/binary"
	"errors"
	"math"
	"sync"
	"time"

	"cloudsync/core/backend"
	"cloudsync/core/crypto"
	"cloudsync/core/erasure"
)

// BackendSpace is the space of one storage.
type BackendSpace struct {
	ID string
	// Known: the provider reported its quota (some, like S3 or WebDAV
	// servers, cannot; offline storages cannot either).
	Known       bool
	Total, Free int64
	Stored      int64 // bytes of this vault's shards there
	Err         string
}

// Space says how full the storages are and how much more fits.
type Space struct {
	Backends []BackendSpace
	// Files: size of all file data in the vault (each block counted once).
	Files int64
	// Writable: how many more bytes of files fit with full redundancy,
	// i.e. before the first storage new shards go to is full. -1: unknown
	// (no storage reports its space). Storages that do not report are
	// taken as unlimited.
	Writable int64
}

// How long a quota answer is reused: About is a network call per storage
// and the app asks for the status often.
const spaceTTL = 2 * time.Minute

type spaceCache struct {
	mu   sync.Mutex
	at   time.Time
	data map[string]aboutResult
}

type aboutResult struct {
	u   backend.Usage
	err error
}

func (e *Engine) about(ctx context.Context) map[string]aboutResult {
	e.space.mu.Lock()
	defer e.space.mu.Unlock()
	if e.space.data != nil && time.Since(e.space.at) < spaceTTL {
		return e.space.data
	}
	c, cancel := context.WithTimeout(ctx, 20*time.Second)
	defer cancel()
	out := map[string]aboutResult{}
	var mu sync.Mutex
	var wg sync.WaitGroup
	for id, s := range e.stores {
		if b, ok := e.cfg.Backend(id); ok && b.Disabled {
			continue // no new data goes there; it may well be gone
		}
		wg.Add(1)
		go func() {
			defer wg.Done()
			u, err := backend.About(c, s)
			mu.Lock()
			out[id] = aboutResult{u, err}
			mu.Unlock()
		}()
	}
	wg.Wait()
	if ctx.Err() == nil {
		e.space.data, e.space.at = out, time.Now()
	}
	return out
}

// Space reports the quota of every storage, what the vault keeps there,
// and how much more can be written.
func (e *Engine) Space(ctx context.Context) Space {
	about := e.about(ctx)
	stored := map[string]int64{}
	var sp Space
	for _, ref := range e.liveBlobs() {
		sp.Files += int64(ref.Size)
		k := max(ref.K, 1)
		shard := int64((8 + ref.Size + crypto.Overhead + k - 1) / k)
		missing := map[int]bool{}
		for _, i := range ref.Missing {
			missing[i] = true
		}
		for i, id := range ref.Placement {
			if !missing[i] {
				stored[id] += shard
			}
		}
	}
	free := map[string]int64{}
	for _, b := range e.cfg.Backends {
		bs := BackendSpace{ID: b.ID, Stored: stored[b.ID]}
		if r, ok := about[b.ID]; ok {
			if r.err == nil {
				bs.Known, bs.Total, bs.Free = true, r.u.Total, r.u.Free
				free[b.ID] = r.u.Free
			} else if !errors.Is(r.err, backend.ErrNoUsage) {
				bs.Err = r.err.Error()
			}
		} else if err := e.openErrs[b.ID]; err != nil {
			bs.Err = err.Error()
		}
		sp.Backends = append(sp.Backends, bs)
	}
	sp.Writable = writable(e.targets, e.cfg.DataShards, e.cfg.DataShards+e.cfg.ParityShards, free)
	return sp
}

// writable estimates how many bytes of files fit before one of targets
// (with free bytes known for some of them) is full. Every blob puts one
// shard of size/k on n of the targets; placement is a hash, so storage i
// gets a fixed share p_i of all blobs and fills after free_i*k/p_i bytes.
func writable(targets []erasure.Target, k, n int, free map[string]int64) int64 {
	if len(targets) < n || k < 1 {
		return 0
	}
	share := placementShares(targets, n)
	best := int64(-1)
	for _, t := range targets {
		f, ok := free[t.ID]
		if !ok || share[t.ID] == 0 {
			continue
		}
		x := float64(f) * float64(k) / share[t.ID]
		if x > math.MaxInt64/2 {
			x = math.MaxInt64 / 2
		}
		if best < 0 || int64(x) < best {
			best = int64(x)
		}
	}
	return best
}

// placementShares returns, for each target, the part of blobs it gets a
// shard of (n/len(targets) when all domains differ).
func placementShares(targets []erasure.Target, n int) map[string]float64 {
	const probes = 2048
	count := map[string]int{}
	id := make([]byte, 8)
	for i := range probes {
		binary.BigEndian.PutUint64(id, uint64(i))
		place, err := erasure.Place(id, targets, n)
		if err != nil {
			return nil
		}
		for _, t := range place {
			count[t]++
		}
	}
	out := map[string]float64{}
	for t, c := range count {
		out[t] = float64(c) / probes
	}
	return out
}
