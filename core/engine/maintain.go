package engine

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"slices"
	"sort"
	"strings"
	"sync"
	"time"

	"cloudsync/core/backend"
	"cloudsync/core/blob"
	"cloudsync/core/erasure"
	"cloudsync/core/index"
	"cloudsync/core/lock"
	"cloudsync/core/vault"
)

// RepairOptions select the optional parts of Repair.
type RepairOptions struct {
	// Rebalance moves shards to the storages new blobs would use, so data
	// spreads over storages added later. It costs a download and an upload
	// per moved shard.
	Rebalance bool
}

// RepairReport says what Repair did.
type RepairReport struct {
	Blobs     int // blobs checked
	Repaired  int // blobs with shards rewritten or moved
	Reencoded int // blobs written again with the vault's current k/m
	Moved     int // blobs rebalanced
	Failed    int // blobs that could not be repaired (fewer than k shards)
	Journal   int // journal segment copies made
	FromLocal int // blobs rebuilt from this device's copy (too few shards left)
	// Damaged lists the files using a blob that could not be repaired:
	// parts of them cannot be read now (sorted).
	Damaged []string
}

// DamagedBlob is a blob Repair could not rebuild, with the files using it
// and why each shard could not be read.
type DamagedBlob struct {
	ID    string
	Paths []string
	Err   error
}

func (d *DamagedBlob) Error() string {
	var parts []string
	var walk func(error)
	walk = func(err error) {
		if j, ok := err.(interface{ Unwrap() []error }); ok {
			for _, e := range j.Unwrap() {
				walk(e)
			}
			return
		}
		parts = append(parts, err.Error())
	}
	walk(d.Err)
	what := "blob " + d.ID
	if len(d.Paths) > 0 {
		what = strings.Join(d.Paths, ", ") + " (blob " + d.ID[:min(8, len(d.ID))] + ")"
	}
	return what + ": " + strings.Join(parts, "; ")
}

func (d *DamagedBlob) Unwrap() error { return d.Err }

// Repair checks every shard of every blob the tree uses (checksums
// included), rewrites lost or corrupted shards, moves shards off storages
// that are disabled or removed, encodes blobs again after a k/m change and
// copies journal segments to storages that miss them. New locations are
// recorded in the journal so every device reads from the right storages.
func (e *Engine) Repair(ctx context.Context, opt RepairOptions) (RepairReport, error) {
	var rep RepairReport
	if _, err := e.pull(ctx); err != nil {
		return rep, err
	}
	places := map[string][]string{}
	refs := map[string]blob.Ref{}
	var errs []error
	live := e.liveBlobs()
	ids := make([]string, 0, len(live))
	for id := range live {
		ids = append(ids, id)
	}
	rep.Blobs = len(ids)
	var mu sync.Mutex
	failed := map[string]error{}
	backend.Limit(len(ids), repairParallel, func(i int) {
		id, ref := ids[i], live[ids[i]]
		if ctx.Err() != nil {
			return
		}
		fail := func(err error) {
			mu.Lock()
			rep.Failed++
			failed[id] = err
			mu.Unlock()
		}
		if e.blobs.Outdated(ref) {
			n, err := e.blobs.Reencode(ctx, ref)
			if err != nil {
				fail(err)
				return
			}
			mu.Lock()
			refs[id] = n
			rep.Reencoded++
			mu.Unlock()
			return
		}
		fixed, changed, err := e.blobs.Repair(ctx, ref)
		if err != nil && ctx.Err() == nil {
			// Too few good shards left in the storages, but this device
			// may have the blob (a pinned or recently read file);
			// RepairFrom checks it against the blob id.
			if pt := e.cache.get(id); pt != nil {
				var lerr error
				if fixed, changed, lerr = e.blobs.RepairFrom(ctx, ref, pt); lerr == nil {
					err = nil
					mu.Lock()
					rep.FromLocal++
					mu.Unlock()
				} else {
					err = errors.Join(err, lerr)
				}
			}
		}
		if err != nil {
			fail(err)
			return
		}
		moved := false
		if opt.Rebalance {
			m, ok, err := e.blobs.Rebalance(ctx, fixed)
			if err != nil {
				mu.Lock()
				errs = append(errs, err)
				mu.Unlock()
			}
			if ok {
				moved, fixed = true, m
			}
		}
		mu.Lock()
		defer mu.Unlock()
		if changed {
			rep.Repaired++
		}
		if moved {
			rep.Moved++
		}
		if !equal(fixed.Placement, ref.Placement) {
			places[id] = fixed.Placement
		}
	})
	if err := ctx.Err(); err != nil {
		return rep, err
	}
	if len(failed) > 0 {
		paths := e.blobPaths(failed)
		seen := map[string]bool{}
		for _, id := range ids { // stable order
			err, ok := failed[id]
			if !ok {
				continue
			}
			errs = append(errs, &DamagedBlob{ID: id, Paths: paths[id], Err: err})
			for _, p := range paths[id] {
				if !seen[p] {
					seen[p] = true
					rep.Damaged = append(rep.Damaged, p)
				}
			}
		}
		sort.Strings(rep.Damaged)
	}
	if len(places) > 0 || len(refs) > 0 {
		op := index.Op{Kind: index.OpPlace, Path: "/", Places: places, Refs: refs}
		if err := e.commit(ctx, []index.Op{op}); err != nil {
			errs = append(errs, err)
		}
	}
	if _, err := e.journal.Compact(ctx, compactAfter, true); err != nil {
		errs = append(errs, err)
	}
	n, err := e.journal.Replicate(ctx)
	rep.Journal = n
	if err != nil {
		errs = append(errs, err)
	}
	return rep, errors.Join(errs...)
}

// blobPaths returns the files (and not yet uploaded changes) using each of
// the blobs in ids, by hex id.
func (e *Engine) blobPaths(ids map[string]error) map[string][]string {
	out := map[string][]string{}
	add := func(p string, v *index.Version) {
		if v == nil {
			return
		}
		for _, c := range v.Chunks {
			id := c.Blob.ID.String()
			if _, ok := ids[id]; ok && !slices.Contains(out[id], p) {
				out[id] = append(out[id], p)
			}
		}
	}
	e.idx.Walk(func(en index.Entry) { add(en.Path, en.Version) })
	e.mu.Lock()
	for _, o := range e.state.Pending {
		add(o.Path, o.Version)
	}
	e.mu.Unlock()
	return out
}

// repairParallel is how many blobs Repair checks at the same time.
const repairParallel = 4

// compactAfter is how many own journal segments are packed into one.
const compactAfter = 64

// liveBlobs returns every blob the tree or a not yet uploaded change uses,
// with its current location, by hex id.
func (e *Engine) liveBlobs() map[string]blob.Ref {
	out := map[string]blob.Ref{}
	add := func(v *index.Version) {
		if v == nil {
			return
		}
		for _, c := range v.Chunks {
			id := c.Blob.ID.String()
			if _, ok := out[id]; !ok {
				out[id] = e.idx.Resolve(c.Blob)
			}
		}
	}
	e.idx.Walk(func(en index.Entry) { add(en.Version) })
	e.mu.Lock()
	for _, o := range e.state.Pending {
		add(o.Version)
	}
	e.mu.Unlock()
	return out
}

// GCReport says what GC did.
type GCReport struct {
	Objects int      // shard objects found on reachable storages
	Unused  int      // of them not used by any file
	Deleted int      // unused for longer than the grace period, removed
	Skipped []string // storages that could not be listed
}

// deleteParallel is how many objects GC deletes on one storage at once.
const deleteParallel = 4

// DefaultGrace is how long an object must stay unused before GC removes it.
// It covers uploads whose journal entry is not written yet and devices
// that were offline with changes using deduplicated blobs; overwritten and
// deleted files stay recoverable from storages for this long.
const DefaultGrace = 7 * 24 * time.Hour

// GC removes shard objects no file uses: blobs of deleted and overwritten
// files, copies left behind by Repair, and uploads that never made it into
// the journal. An object is only removed when this device has seen it
// unused for at least grace (marks are kept in the data dir), so devices do
// not need to agree on a moment.
func (e *Engine) GC(ctx context.Context, grace time.Duration) (GCReport, error) {
	var rep GCReport
	if _, err := e.pull(ctx); err != nil {
		return rep, fmt.Errorf("gc needs an up to date index: %w", err)
	}
	live := map[blob.Shard]bool{}
	for _, ref := range e.liveBlobs() {
		for _, sh := range e.blobs.Shards(ref) {
			live[sh] = true
		}
	}
	marks := e.loadMarks()
	now := time.Now()
	next := map[string]time.Time{}
	var errs []error
	var mu sync.Mutex
	backend.Limit(len(e.cfg.Backends), len(e.cfg.Backends), func(i int) {
		b := e.cfg.Backends[i]
		if e.stores[b.ID] == nil {
			mu.Lock()
			rep.Skipped = append(rep.Skipped, b.Name)
			mu.Unlock()
			return
		}
		names, err := e.blobs.Objects(ctx, b.ID)
		if err != nil {
			mu.Lock()
			defer mu.Unlock()
			rep.Skipped = append(rep.Skipped, b.Name)
			// Keep its marks: an unreachable storage keeps its clock.
			for k, t := range marks {
				if strings.HasPrefix(k, b.ID+"/") {
					next[k] = t
				}
			}
			return
		}
		var old []string // unused for the whole grace period
		since := map[string]time.Time{}
		mu.Lock()
		for _, n := range names {
			rep.Objects++
			if live[blob.Shard{Store: b.ID, Name: n}] {
				continue
			}
			rep.Unused++
			key := b.ID + "/" + n
			first, ok := marks[key]
			if !ok {
				first = now
			}
			if now.Sub(first) >= grace {
				old = append(old, n)
				since[n] = first
			} else {
				next[key] = first
			}
		}
		mu.Unlock()
		backend.Limit(len(old), deleteParallel, func(j int) {
			err := e.blobs.DeleteObject(ctx, b.ID, old[j])
			mu.Lock()
			defer mu.Unlock()
			if err != nil {
				errs = append(errs, err)
				next[b.ID+"/"+old[j]] = since[old[j]]
				return
			}
			rep.Deleted++
		})
	})
	sort.Strings(rep.Skipped)
	if err := e.saveMarks(next); err != nil {
		errs = append(errs, err)
	}
	return rep, errors.Join(errs...)
}

func (e *Engine) marksPath() string { return filepath.Join(e.opt.DataDir, "gc.json") }

func (e *Engine) loadMarks() map[string]time.Time {
	m := map[string]time.Time{}
	if data, err := os.ReadFile(e.marksPath()); err == nil {
		_ = json.Unmarshal(data, &m)
	}
	return m
}

func (e *Engine) saveMarks(m map[string]time.Time) error {
	data, err := json.Marshal(m)
	if err != nil {
		return err
	}
	return writeFileAtomic(e.marksPath(), data)
}

// SetRedundancy changes k and m for new blobs. Existing blobs keep their
// layout until Repair encodes them again. The engine must be reopened
// afterwards (ReloadNeeded reports true).
func (e *Engine) SetRedundancy(k, m int) error {
	if _, err := erasure.New(k, m); err != nil {
		return err
	}
	err := e.v.Update(func(c *vault.Config) error {
		if n := len(c.ActiveBackends()); n < k+m {
			return fmt.Errorf("k+m=%d needs %d enabled storages, there are %d", k+m, k+m, n)
		}
		c.DataShards, c.ParityShards = k, m
		return nil
	})
	if err == nil {
		e.reload.Store(true)
	}
	return err
}

func equal(a, b []string) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if a[i] != b[i] {
			return false
		}
	}
	return true
}

// Lock takes the write lock for p. It fails with *lock.LockedError if
// another device has p open for writing.
func (e *Engine) Lock(ctx context.Context, p string) (*lock.Lock, error) {
	return e.locks.Acquire(ctx, index.Clean(p))
}

// Locks returns who holds the write lock of each locked path among paths.
func (e *Engine) Locks(ctx context.Context, paths []string) map[string]*lock.Lease {
	clean := make([]string, len(paths))
	for i, p := range paths {
		clean[i] = index.Clean(p)
	}
	return e.locks.Locked(ctx, clean)
}

// RemoveBackend deletes a disabled storage from the vault once no file
// uses it any more (run Repair after disabling it). The data left on it is
// not deleted. force removes it anyway: for a storage that is gone for
// good, whose shards Repair cannot move; they count as lost and Repair
// rebuilds every blob that has k shards elsewhere.
func (e *Engine) RemoveBackend(id string, force bool) error {
	b, ok := e.cfg.Backend(id)
	if !ok {
		return fmt.Errorf("no storage %s", id)
	}
	if !b.Disabled {
		return errors.New("disable the storage and run repair first")
	}
	used := 0
	for _, ref := range e.liveBlobs() {
		for _, s := range ref.Placement {
			if s == id {
				used++
				break
			}
		}
	}
	if used > 0 && !force {
		return fmt.Errorf("%d blobs still have shards on %s: run repair first, or remove it anyway if it is gone for good", used, b.Name)
	}
	err := e.v.Update(func(c *vault.Config) error {
		for i := range c.Backends {
			if c.Backends[i].ID == id {
				c.Backends = append(c.Backends[:i], c.Backends[i+1:]...)
				return nil
			}
		}
		return nil
	})
	if err == nil {
		e.reload.Store(true)
	}
	return err
}

// LockHolder returns who holds the write lock for p (nil if nobody).
func (e *Engine) LockHolder(ctx context.Context, p string) (*lock.Lease, error) {
	return e.locks.Holder(ctx, index.Clean(p))
}
