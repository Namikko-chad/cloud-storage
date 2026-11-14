package index

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"

	"cloudsync/core/backend"
	"cloudsync/core/crypto"
)

// Journal reads and writes journal segments. Segment j/<device>/<seq> holds
// a batch of ops of one device; it is encrypted and copied to every
// storage, since it is small and every device needs all of them.
type Journal struct {
	device  string
	key     crypto.Key
	stores  []backend.Store
	minCopy int
	// CacheDir, if set, keeps a local copy of every segment (still
	// encrypted), so a restart reads nothing but listings from storages.
	CacheDir string
	mu       sync.Mutex
	seq      uint64                // last segment written by this device
	loaded   map[string]bool       // segment names already read
	packed   map[string][]seqRange // device → ranges of packs already read
	packTo   uint64                // highest seq of this device's packs seen

	// Coverage per storage from the last full listing (Pull), so Counts
	// does not list every storage again right after a sync.
	cmu       sync.Mutex
	counted   map[string]int
	countedAt time.Time
	// appends counts this device's segment writes. A listing that spans
	// one is not a snapshot: storages listed after the write show one
	// segment more, and the others would look behind.
	appends uint64
}

// countsFresh is how long Counts trusts the coverage seen by the last listing.
const countsFresh = 2 * time.Minute

func (j *Journal) setCounts(c map[string]int) {
	var own map[string]int
	if c != nil {
		own = make(map[string]int, len(c))
		for id, n := range c {
			own[id] = n
		}
	}
	j.cmu.Lock()
	j.counted, j.countedAt = own, time.Now()
	j.cmu.Unlock()
}

// appendGen returns the number of segment writes so far (see appends).
func (j *Journal) appendGen() uint64 {
	j.cmu.Lock()
	defer j.cmu.Unlock()
	return j.appends
}

// setCountsSince keeps c only if no segment was written since gen;
// otherwise it drops the cached counts so the next Counts lists again.
func (j *Journal) setCountsSince(c map[string]int, gen uint64) bool {
	if j.appendGen() != gen {
		j.setCounts(nil)
		return false
	}
	j.setCounts(c)
	return true
}

type seqRange struct{ from, to uint64 }

func (r seqRange) has(seq uint64) bool { return seq >= r.from && seq <= r.to }

// NewJournal returns a journal for device. A segment write succeeds when it
// reached minCopies storages (use m+1 so that losing m storages keeps it).
func NewJournal(device string, master crypto.Key, stores []backend.Store, minCopies int) *Journal {
	if minCopies < 1 {
		minCopies = 1
	}
	if minCopies > len(stores) {
		minCopies = len(stores)
	}
	return &Journal{
		device:  device,
		key:     master.Derive("journal", nil),
		stores:  stores,
		minCopy: minCopies,
		loaded:  map[string]bool{},
		packed:  map[string][]seqRange{},
	}
}

func segName(device string, seq uint64) string {
	return fmt.Sprintf("j/%s/%020d", device, seq)
}

// A pack holds the ops of segments from..to of one device (journal
// compaction): one object to read instead of many.
func packName(device string, r seqRange) string {
	return fmt.Sprintf("j/%s/p%020d-%020d", device, r.from, r.to)
}

// parseName returns the device and seq range of a segment or pack name.
func parseName(name string) (dev string, r seqRange, pack bool, ok bool) {
	dev, base := path.Base(path.Dir(name)), path.Base(name)
	if strings.HasPrefix(base, "p") {
		a, b, found := strings.Cut(base[1:], "-")
		from, err1 := strconv.ParseUint(a, 10, 64)
		to, err2 := strconv.ParseUint(b, 10, 64)
		if !found || err1 != nil || err2 != nil || from > to {
			return "", r, false, false
		}
		return dev, seqRange{from, to}, true, true
	}
	seq, err := strconv.ParseUint(base, 10, 64)
	if err != nil {
		return "", r, false, false
	}
	return dev, seqRange{seq, seq}, false, true
}

// Append writes ops as a new segment.
func (j *Journal) Append(ctx context.Context, ops []Op) error {
	if len(ops) == 0 {
		return nil
	}
	j.mu.Lock()
	defer j.mu.Unlock()
	if j.seq == 0 {
		if err := j.findSeq(ctx); err != nil {
			return err
		}
	}
	name := segName(j.device, j.seq+1)
	plain, err := json.Marshal(ops)
	if err != nil {
		return err
	}
	sealed, err := crypto.Seal(j.key, plain, []byte(name))
	if err != nil {
		return err
	}
	// The number is used up even on failure: a partial copy may exist, and a
	// name must never get two different contents. The caller retries the
	// same ops in a new segment; duplicates are dropped by op id.
	j.seq++
	j.loaded[name] = true
	j.cachePut(name, sealed)
	j.cmu.Lock()
	j.appends++
	j.cmu.Unlock()

	// Writes go on in the background after the call returns: a slow
	// storage gets its copy later instead of holding up every change.
	bg, cancel := context.WithTimeout(context.WithoutCancel(ctx), backgroundTimeout)
	results := make(chan error, len(j.stores))
	var wg sync.WaitGroup
	for _, s := range j.stores {
		wg.Add(1)
		go func(s backend.Store) {
			defer wg.Done()
			err := backend.PutNew(bg, s, name, sealed)
			if err == nil {
				j.cmu.Lock()
				if _, seen := j.counted[s.ID()]; seen {
					j.counted[s.ID()]++
				}
				j.cmu.Unlock()
			} else {
				err = fmt.Errorf("%s: %w", s.ID(), err)
			}
			results <- err
		}(s)
	}
	go func() { wg.Wait(); cancel() }()
	ok, done := 0, 0
	var errs []error
	var straggle <-chan time.Time
	for done < len(j.stores) {
		select {
		case err := <-results:
			done++
			if err != nil {
				errs = append(errs, err)
			} else {
				ok++
			}
		case <-straggle:
			return nil
		case <-ctx.Done():
			return ctx.Err()
		}
		if ok >= j.minCopy && straggle == nil {
			straggle = time.After(straggleWait)
		}
		if ok+len(j.stores)-done < j.minCopy {
			break
		}
	}
	if ok < j.minCopy {
		return fmt.Errorf("journal: segment stored on %d storages, need %d: %w", ok, j.minCopy, errors.Join(errs...))
	}
	return nil
}

// straggleWait is how long a write waits for the remaining storages once
// enough of them have a copy; the rest finish in the background.
const straggleWait = 300 * time.Millisecond

// backgroundTimeout bounds writes that go on after the call returned.
const backgroundTimeout = 5 * time.Minute

// findSeq recovers the last segment number of this device from storages
// (a reinstalled device keeps its id and continues the numbering).
func (j *Journal) findSeq(ctx context.Context) error {
	var mu sync.Mutex
	reached := 0
	backend.Each(j.stores, func(s backend.Store) {
		names, err := s.List(ctx, "j/"+j.device)
		if err != nil {
			return
		}
		mu.Lock()
		defer mu.Unlock()
		reached++
		for _, n := range names {
			if _, r, _, ok := parseName(n); ok && r.to > j.seq {
				j.seq = r.to
			}
		}
	})
	if reached < j.minCopy {
		return errors.New("journal: too few storages reachable to continue the journal")
	}
	return nil
}

// listing is what one storage holds of the journal.
type listing struct {
	names    []string // every segment and pack name
	complete bool     // every device folder was listed
	err      error    // the storage could not be listed at all
}

// listAll lists the journal on every storage at the same time.
func (j *Journal) listAll(ctx context.Context) []listing {
	out := make([]listing, len(j.stores))
	backend.Limit(len(j.stores), len(j.stores), func(i int) {
		s := j.stores[i]
		devs, err := s.ListDirs(ctx, "j")
		if err != nil {
			out[i].err = fmt.Errorf("%s: %w", s.ID(), err)
			return
		}
		out[i].complete = true
		for _, d := range devs {
			names, err := s.List(ctx, d)
			if err != nil {
				out[i].complete = false
				continue
			}
			out[i].names = append(out[i].names, names...)
		}
	})
	return out
}

// readParallel is how many segments are downloaded at the same time.
const readParallel = 8

// Pull returns ops from segments not read yet, from any device.
func (j *Journal) Pull(ctx context.Context) ([]Op, error) {
	where := map[string][]backend.Store{} // segment → storages that have it
	reached := 0
	var errs []error
	counts := map[string]int{}
	gen := j.appendGen()
	for i, l := range j.listAll(ctx) {
		s := j.stores[i]
		if l.err != nil {
			errs = append(errs, l.err)
			continue
		}
		reached++
		byDev := map[string][]string{}
		for _, n := range l.names {
			byDev[path.Dir(n)] = append(byDev[path.Dir(n)], n)
			j.mu.Lock()
			done := j.loaded[n]
			j.mu.Unlock()
			if !done {
				where[n] = append(where[n], s)
			}
		}
		if l.complete {
			cov := 0
			for _, names := range byDev {
				cov += coverage(names)
			}
			counts[s.ID()] = cov
		}
	}
	j.setCountsSince(counts, gen)
	if reached == 0 && len(j.stores) > 0 {
		return nil, fmt.Errorf("journal: no storage reachable: %w", errors.Join(errs...))
	}
	var packs, segs []string
	for n := range where {
		if _, _, pack, ok := parseName(n); ok && pack {
			packs = append(packs, n)
		} else if ok {
			segs = append(segs, n)
		}
	}
	var mu sync.Mutex
	var out []Op
	read := func(names []string) {
		backend.Limit(len(names), readParallel, func(i int) {
			n := names[i]
			dev, r, pack, _ := parseName(n)
			if !pack && j.covered(dev, r.from) {
				j.mu.Lock()
				j.loaded[n] = true
				j.mu.Unlock()
				return
			}
			ops, err := j.read(ctx, n, where[n])
			mu.Lock()
			defer mu.Unlock()
			if err != nil {
				errs = append(errs, err)
				return
			}
			j.mu.Lock()
			j.loaded[n] = true
			if pack {
				j.packed[dev] = append(j.packed[dev], r)
				if dev == j.device && r.to > j.packTo {
					j.packTo = r.to
				}
			}
			j.mu.Unlock()
			out = append(out, ops...)
		})
	}
	// Packs first: segments a pack already covers are not downloaded.
	read(packs)
	read(segs)
	if len(out) == 0 && len(errs) > 0 && reached == 0 {
		return nil, errors.Join(errs...)
	}
	return out, nil
}

func (j *Journal) covered(dev string, seq uint64) bool {
	j.mu.Lock()
	defer j.mu.Unlock()
	for _, r := range j.packed[dev] {
		if r.has(seq) {
			return true
		}
	}
	return false
}

func (j *Journal) read(ctx context.Context, name string, from []backend.Store) ([]Op, error) {
	if sealed := j.cacheGet(name); sealed != nil {
		if ops, err := j.decode(name, sealed); err == nil {
			return ops, nil
		}
	}
	var errs []error
	for _, s := range backend.Fastest(from) {
		sealed, err := s.Get(ctx, name)
		if err != nil {
			errs = append(errs, err)
			continue
		}
		ops, err := j.decode(name, sealed)
		if err != nil {
			errs = append(errs, fmt.Errorf("on %s: %w", s.ID(), err))
			continue
		}
		j.cachePut(name, sealed)
		return ops, nil
	}
	return nil, fmt.Errorf("journal: read %s: %w", name, errors.Join(errs...))
}

func (j *Journal) decode(name string, sealed []byte) ([]Op, error) {
	plain, err := crypto.Open(j.key, sealed, []byte(name))
	if err != nil {
		return nil, fmt.Errorf("%s: %w", name, err)
	}
	var ops []Op
	if err := json.Unmarshal(plain, &ops); err != nil {
		return nil, err
	}
	dev := path.Base(path.Dir(name))
	for _, o := range ops {
		if o.Device != dev {
			return nil, fmt.Errorf("journal: %s contains ops of another device", name)
		}
	}
	return ops, nil
}

func (j *Journal) cachePath(name string) string {
	return filepath.Join(j.CacheDir, filepath.FromSlash(name))
}

func (j *Journal) cacheGet(name string) []byte {
	if j.CacheDir == "" {
		return nil
	}
	d, _ := os.ReadFile(j.cachePath(name))
	return d
}

func (j *Journal) cachePut(name string, sealed []byte) {
	if j.CacheDir == "" {
		return
	}
	p := j.cachePath(name)
	if os.MkdirAll(filepath.Dir(p), 0o700) == nil {
		_ = os.WriteFile(p, sealed, 0o600)
	}
}

// Replicate copies segments to storages that miss them (after an outage or
// when a storage was added). It returns how many copies were made.
func (j *Journal) Replicate(ctx context.Context) (int, error) {
	defer j.setCounts(nil)              // copies change coverage: list again next time
	has := map[string]map[string]bool{} // segment → store id set
	for i, l := range j.listAll(ctx) {
		if l.err != nil {
			return 0, l.err
		}
		if !l.complete {
			return 0, fmt.Errorf("journal: %s could not be listed completely", j.stores[i].ID())
		}
		for _, n := range l.names {
			if has[n] == nil {
				has[n] = map[string]bool{}
			}
			has[n][j.stores[i].ID()] = true
		}
	}
	var todo []string
	for name, ids := range has {
		if len(ids) < len(j.stores) {
			todo = append(todo, name)
		}
	}
	var mu sync.Mutex
	copies := 0
	var errs []error
	backend.Limit(len(todo), readParallel, func(i int) {
		name := todo[i]
		ids := has[name]
		var data []byte
		var from []backend.Store
		for _, s := range j.stores {
			if ids[s.ID()] {
				from = append(from, s)
			}
		}
		for _, s := range backend.Fastest(from) {
			if d, err := s.Get(ctx, name); err == nil {
				data = d
				break
			}
		}
		if data == nil {
			return
		}
		for _, s := range j.stores {
			if ids[s.ID()] {
				continue
			}
			err := backend.PutNew(ctx, s, name, data)
			mu.Lock()
			if err != nil {
				errs = append(errs, err)
			} else {
				copies++
			}
			mu.Unlock()
		}
	})
	return copies, errors.Join(errs...)
}

// Counts returns how many journal segments each reachable storage covers
// (a pack counts for every segment in it). A storage covering fewer than
// the others is behind (new, or lost data).
//
// Right after a Pull it answers from that Pull's listing (kept countsFresh),
// so a status check does not list slow storages a second time.
func (j *Journal) Counts(ctx context.Context) map[string]int {
	j.cmu.Lock()
	if j.counted != nil && time.Since(j.countedAt) < countsFresh {
		out := make(map[string]int, len(j.counted))
		for id, n := range j.counted {
			out[id] = n
		}
		j.cmu.Unlock()
		return out
	}
	j.cmu.Unlock()
	// A write during the listing skews it; list again (a few times at most).
	for try := 0; ; try++ {
		gen := j.appendGen()
		out := j.listCounts(ctx)
		if j.setCountsSince(out, gen) || try == 2 || ctx.Err() != nil {
			return out
		}
	}
}

// listCounts lists every storage in parallel and returns its coverage.
func (j *Journal) listCounts(ctx context.Context) map[string]int {
	out := map[string]int{}
	var mu sync.Mutex
	var wg sync.WaitGroup
	for _, s := range j.stores {
		wg.Add(1)
		go func(s backend.Store) {
			defer wg.Done()
			devs, err := s.ListDirs(ctx, "j")
			if err != nil {
				return
			}
			n := 0
			for _, d := range devs {
				names, err := s.List(ctx, d)
				if err != nil {
					return
				}
				n += coverage(names)
			}
			mu.Lock()
			out[s.ID()] = n
			mu.Unlock()
		}(s)
	}
	wg.Wait()
	return out
}

// coverage counts the distinct segment numbers names of one device cover.
// Overlapping packs and duplicate names (Drive and Mega allow two objects
// with one name) count once.
func coverage(names []string) int {
	var rs []seqRange
	for _, n := range names {
		if _, r, pack, ok := parseName(n); ok {
			if !pack {
				r.to = r.from
			}
			rs = append(rs, r)
		}
	}
	sort.Slice(rs, func(a, b int) bool { return rs[a].from < rs[b].from })
	n := 0
	var cur seqRange
	for i, r := range rs {
		if i > 0 && r.from <= cur.to+1 {
			cur.to = max(cur.to, r.to)
			continue
		}
		if i > 0 {
			n += int(cur.to - cur.from + 1)
		}
		cur = r
	}
	if len(rs) > 0 {
		n += int(cur.to - cur.from + 1)
	}
	return n
}

// Compact packs this device's segments into one object once at least min
// of them are not packed yet, and removes segments a pack covers. Only the
// owner rewrites its journal. Every segment that was written successfully
// is on minCopies storages, so with all but minCopies-1 storages reachable
// the pack is complete. Without cleanup it does nothing (not even a
// listing) while fewer than min segments were written since the last pack.
func (j *Journal) Compact(ctx context.Context, min int, cleanup bool) (int, error) {
	j.mu.Lock()
	defer j.mu.Unlock()
	if j.seq == 0 {
		if err := j.findSeq(ctx); err != nil {
			return 0, err
		}
	}
	if !cleanup && j.seq-j.packTo < uint64(min) {
		return 0, nil // call Pull first so packTo is known
	}
	dir := "j/" + j.device
	listed := map[string][]string{} // store id → own names
	where := map[string][]backend.Store{}
	var lmu sync.Mutex
	backend.Each(j.stores, func(s backend.Store) {
		names, err := s.List(ctx, dir)
		if err != nil {
			return
		}
		lmu.Lock()
		defer lmu.Unlock()
		listed[s.ID()] = names
		for _, n := range names {
			where[n] = append(where[n], s)
		}
	})
	if len(listed) < len(j.stores)-j.minCopy+1 {
		return 0, errors.New("journal: too few storages reachable to compact")
	}
	var packs []seqRange
	for n := range where {
		if _, r, pack, ok := parseName(n); ok && pack {
			packs = append(packs, r)
			if r.to > j.packTo {
				j.packTo = r.to
			}
		}
	}
	in := func(seq uint64) bool {
		for _, r := range packs {
			if r.has(seq) {
				return true
			}
		}
		return false
	}
	var loose []string
	for n := range where {
		if _, r, pack, ok := parseName(n); ok && !pack && !in(r.from) {
			loose = append(loose, n)
		}
	}
	sort.Strings(loose)
	made := 0
	if len(loose) >= min {
		parts := make([][]Op, len(loose))
		rerrs := make([]error, len(loose))
		backend.Limit(len(loose), readParallel, func(i int) {
			parts[i], rerrs[i] = j.read(ctx, loose[i], where[loose[i]])
		})
		var ops []Op
		for i := range loose {
			if rerrs[i] != nil {
				return 0, rerrs[i] // never pack over a segment we could not read
			}
			ops = append(ops, parts[i]...)
		}
		_, first, _, _ := parseName(loose[0])
		_, last, _, _ := parseName(loose[len(loose)-1])
		r := seqRange{first.from, last.to}
		name := packName(j.device, r)
		plain, err := json.Marshal(ops)
		if err != nil {
			return 0, err
		}
		sealed, err := crypto.Seal(j.key, plain, []byte(name))
		if err != nil {
			return 0, err
		}
		ok := 0
		backend.Each(j.stores, func(s backend.Store) {
			lmu.Lock()
			_, reached := listed[s.ID()]
			lmu.Unlock()
			if !reached {
				return
			}
			if err := backend.PutNew(ctx, s, name, sealed); err == nil {
				lmu.Lock()
				ok++
				listed[s.ID()] = append(listed[s.ID()], name)
				lmu.Unlock()
			}
		})
		if ok < j.minCopy {
			return 0, fmt.Errorf("journal: pack stored on %d storages, need %d", ok, j.minCopy)
		}
		j.cachePut(name, sealed)
		j.loaded[name] = true
		j.packed[j.device] = append(j.packed[j.device], r)
		j.packTo = r.to
		made = 1
	}
	// Drop segments a pack on the same storage covers.
	backend.Each(j.stores, func(s backend.Store) {
		names := listed[s.ID()]
		var have []seqRange
		for _, n := range names {
			if _, r, pack, ok := parseName(n); ok && pack {
				have = append(have, r)
			}
		}
		for _, n := range names {
			_, r, pack, ok := parseName(n)
			if !ok || pack {
				continue
			}
			for _, p := range have {
				if p.has(r.from) {
					_ = s.Delete(ctx, n)
					break
				}
			}
		}
	})
	return made, nil
}
