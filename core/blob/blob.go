// Package blob stores encrypted blobs (file chunks, packs) spread over
// storages: plaintext → AEAD → Reed-Solomon k+m → one shard per storage.
// Reading needs any k shards; storages are tried in placement order and a
// slow or broken one is replaced by the next.
package blob

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"slices"
	"sort"
	"sync"
	"time"

	"cloudsync/core/backend"
	"cloudsync/core/crypto"
	"cloudsync/core/erasure"
)

// Ref locates a blob. It goes into the index.
type Ref struct {
	ID        HexID    `json:"id"`        // keyed hash of the plaintext
	Size      int      `json:"size"`      // plaintext size
	Placement []string `json:"placement"` // backend id holding shard i
	K         int      `json:"k"`
	Missing   []int    `json:"missing,omitempty"` // shards not written (needs repair)
	// Gen changes when the blob is encoded again (new k/m): shards of each
	// generation have their own names, so readers of the old ref never see
	// shards of the new layout.
	Gen int `json:"gen,omitempty"`
}

// HexID is a byte id serialized as hex.
type HexID []byte

func (h HexID) String() string { return hex.EncodeToString(h) }

func (h HexID) MarshalText() ([]byte, error) { return []byte(hex.EncodeToString(h)), nil }

func (h *HexID) UnmarshalText(b []byte) error {
	d, err := hex.DecodeString(string(b))
	*h = d
	return err
}

// Store puts and gets blobs.
type Store struct {
	codec   *erasure.Codec
	targets []erasure.Target
	stores  map[string]backend.Store
	idKey   crypto.Key
	nameKey crypto.Key
	dataKey crypto.Key
}

// New returns a blob store writing to targets. stores must contain every
// target and may contain more (old storages still holding shards).
func New(master crypto.Key, k, m int, targets []erasure.Target, stores map[string]backend.Store) (*Store, error) {
	codec, err := erasure.New(k, m)
	if err != nil {
		return nil, err
	}
	if len(targets) < codec.N() {
		return nil, fmt.Errorf("blob: %d storages configured, k+m=%d needed", len(targets), codec.N())
	}
	for _, t := range targets {
		if stores[t.ID] == nil {
			return nil, fmt.Errorf("blob: storage %s not open", t.ID)
		}
	}
	return &Store{
		codec:   codec,
		targets: targets,
		stores:  stores,
		idKey:   master.Derive("blob-id", nil),
		nameKey: master.Derive("blob-name", nil),
		dataKey: master.Derive("blob-data", nil),
	}, nil
}

// ID returns the id a blob with this plaintext gets (for deduplication).
func (s *Store) ID(plaintext []byte) HexID { return s.idKey.MAC(plaintext) }

// K and N return the layout new blobs are written with.
func (s *Store) K() int { return s.codec.K }
func (s *Store) N() int { return s.codec.N() }

// ShardName is the object name of shard i of blob id (generation 0).
func (s *Store) ShardName(id []byte, i int) string { return s.shardName(id, 0, i) }

func (s *Store) shardName(id []byte, gen, i int) string {
	tag := []byte{byte(i)}
	if gen > 0 {
		tag = fmt.Appendf(tag, "/%d", gen)
	}
	n := s.nameKey.Name(id, tag)
	return "d/" + n[:2] + "/" + n
}

// Shard is where one shard of a blob lives.
type Shard struct{ Store, Name string }

// Shards lists the objects holding ref.
func (s *Store) Shards(ref Ref) []Shard {
	out := make([]Shard, len(ref.Placement))
	for i, id := range ref.Placement {
		out[i] = Shard{id, s.shardName(ref.ID, ref.Gen, i)}
	}
	return out
}

// Objects lists the shard objects on storage id (for garbage collection).
func (s *Store) Objects(ctx context.Context, id string) ([]string, error) {
	st := s.stores[id]
	if st == nil {
		return nil, fmt.Errorf("storage %s not open", id)
	}
	dirs, err := st.ListDirs(ctx, "d")
	if err != nil {
		return nil, err
	}
	lists := make([][]string, len(dirs))
	errs := make([]error, len(dirs))
	backend.Limit(len(dirs), listParallel, func(i int) {
		lists[i], errs[i] = st.List(ctx, dirs[i])
	})
	var out []string
	for i := range dirs {
		if errs[i] != nil {
			return nil, errs[i]
		}
		out = append(out, lists[i]...)
	}
	return out, nil
}

// listParallel is how many shard folders of one storage are listed at once.
const listParallel = 4

// DeleteObject removes one object from storage id.
func (s *Store) DeleteObject(ctx context.Context, id, name string) error {
	st := s.stores[id]
	if st == nil {
		return fmt.Errorf("storage %s not open", id)
	}
	return st.Delete(ctx, name)
}

// Outdated reports whether ref was written with another k/m than the
// store uses now.
func (s *Store) Outdated(ref Ref) bool {
	return ref.K != s.codec.K || len(ref.Placement) != s.codec.N()
}

// Put stores plaintext. It succeeds when at least k shards are written;
// shards that failed are listed in Ref.Missing for a later Repair.
func (s *Store) Put(ctx context.Context, plaintext []byte) (Ref, error) {
	return s.put(ctx, plaintext, 0)
}

// Reencode writes ref again with the store's current k/m as a new
// generation. The old shards stay until garbage collection removes them.
func (s *Store) Reencode(ctx context.Context, ref Ref) (Ref, error) {
	pt, err := s.Get(ctx, ref)
	if err != nil {
		return ref, err
	}
	out, err := s.put(ctx, pt, ref.Gen+1)
	if err != nil {
		return ref, err
	}
	if len(out.Missing) > 0 {
		return ref, fmt.Errorf("blob %s: %d shards not written", ref.ID, len(out.Missing))
	}
	return out, nil
}

func (s *Store) put(ctx context.Context, plaintext []byte, gen int) (Ref, error) {
	id := s.ID(plaintext)
	// Deterministic: two writes of the same blob (two devices, a retry)
	// produce identical shards, so shards of the same name never mix.
	ct, err := crypto.SealDeterministic(s.dataKey.Derive("blob", id), plaintext, id)
	if err != nil {
		return Ref{}, err
	}
	shards, err := s.codec.Encode(ct)
	if err != nil {
		return Ref{}, err
	}
	place, err := erasure.Place(id, s.targets, s.codec.N())
	if err != nil {
		return Ref{}, err
	}
	ref := Ref{ID: id, Size: len(plaintext), Placement: place, K: s.codec.K, Gen: gen}
	errs := make([]error, len(shards))
	var wg sync.WaitGroup
	for i := range shards {
		wg.Add(1)
		go func(i int) {
			defer wg.Done()
			errs[i] = s.putShard(ctx, place[i], ref, i, shards[i])
		}(i)
	}
	wg.Wait()
	for i, e := range errs {
		if e != nil {
			ref.Missing = append(ref.Missing, i)
		}
	}
	if len(shards)-len(ref.Missing) < s.codec.K {
		return Ref{}, fmt.Errorf("blob: only %d of %d shards written: %w",
			len(shards)-len(ref.Missing), len(shards), errors.Join(errs...))
	}
	return ref, nil
}

// Get returns the plaintext of ref.
func (s *Store) Get(ctx context.Context, ref Ref) ([]byte, error) {
	shards, err := s.fetch(ctx, ref, ref.K)
	if err != nil {
		return nil, err
	}
	pt, err := s.decrypt(ref, shards)
	if !errors.Is(err, crypto.ErrDecrypt) {
		return pt, err
	}
	// Shards of two different encryptions are mixed (written by versions
	// that sealed blobs with a random nonce): fetch all and look for k that
	// belong together.
	all, ferr := s.fetch(ctx, ref, len(ref.Placement))
	if ferr != nil && !errors.Is(ferr, errPartial) {
		return nil, err
	}
	pt, _, rerr := s.recoverMixed(ref, all)
	if rerr != nil {
		return nil, err
	}
	return pt, nil
}

// Repair makes sure every shard of ref exists and belongs to one valid
// encoding (missing, corrupted or mixed-up shards are rewritten). Shards whose storage is no
// longer a target are moved to a target not holding a shard of ref yet.
// It returns the updated Ref and whether anything changed.
func (s *Store) Repair(ctx context.Context, ref Ref) (Ref, bool, error) {
	shards, err := s.fetch(ctx, ref, len(ref.Placement))
	if err != nil && !errors.Is(err, errPartial) {
		return ref, false, err
	}
	codec, err := erasure.New(ref.K, len(ref.Placement)-ref.K)
	if err != nil {
		return ref, false, err
	}
	// Find a consistent set of k shards (never spread corrupted data) and
	// encode it again: shards that differ from that are rewritten.
	_, ct, err := s.recoverMixed(ref, shards)
	if err != nil {
		return ref, false, err
	}
	good, err := codec.Encode(ct)
	if err != nil {
		return ref, false, err
	}
	return s.rewrite(ctx, ref, shards, good)
}

// RepairFrom repairs ref from its plaintext kept on this device (a pinned
// file) when the storages no longer have k shards of it. Encryption is
// deterministic, so the shards come out as they were written; only the
// ones missing or wrong are uploaded.
func (s *Store) RepairFrom(ctx context.Context, ref Ref, plaintext []byte) (Ref, bool, error) {
	if !bytes.Equal(s.ID(plaintext), ref.ID) {
		return ref, false, fmt.Errorf("blob %s: local copy does not match", ref.ID)
	}
	if len(plaintext) != ref.Size {
		return ref, false, fmt.Errorf("blob %s: local copy has another size", ref.ID)
	}
	codec, err := erasure.New(ref.K, len(ref.Placement)-ref.K)
	if err != nil {
		return ref, false, err
	}
	ct, err := crypto.SealDeterministic(s.dataKey.Derive("blob", ref.ID), plaintext, ref.ID)
	if err != nil {
		return ref, false, err
	}
	good, err := codec.Encode(ct)
	if err != nil {
		return ref, false, err
	}
	shards, _ := s.fetch(ctx, ref, len(ref.Placement)) // what is still there
	if shards == nil {
		shards = make([][]byte, len(ref.Placement))
	}
	return s.rewrite(ctx, ref, shards, good)
}

// rewrite uploads the shards of good that differ from what was read
// (shards; nil = unreadable), moving those on storages that are no longer
// targets.
func (s *Store) rewrite(ctx context.Context, ref Ref, shards, good [][]byte) (Ref, bool, error) {
	need := false // a shard is missing, wrong or on a storage that is gone
	isTarget := map[string]bool{}
	for _, t := range s.targets {
		isTarget[t.ID] = true
	}
	for _, id := range ref.Placement {
		if !isTarget[id] {
			need = true
		}
	}
	bad := make([]bool, len(good))
	for i := range good {
		if i >= len(shards) || !bytes.Equal(shards[i], good[i]) {
			bad[i], need = true, true
		}
	}
	if !need && len(ref.Missing) == 0 {
		return ref, false, nil
	}

	out := ref
	out.Placement = append([]string{}, ref.Placement...)
	out.Missing = nil
	used := map[string]bool{}
	for _, id := range out.Placement {
		if isTarget[id] {
			used[id] = true
		}
	}
	for i, id := range out.Placement {
		moved := false
		if !isTarget[id] {
			id = s.spareTarget(ref.ID, used)
			if id == "" {
				return ref, false, errors.New("blob: no storage left to move a shard to")
			}
			used[id] = true
			out.Placement[i] = id
			moved = true
		}
		if moved || bad[i] || slices.Contains(ref.Missing, i) {
			if err := s.putShard(ctx, id, ref, i, good[i]); err != nil {
				out.Missing = append(out.Missing, i)
			}
		}
	}
	return out, true, nil
}

// Rebalance moves shards of ref to the storages a new blob with the same
// id would use (after storages were added), so data spreads evenly. Only
// shards on storages outside that set move. It returns the new Ref and
// whether anything moved; the old copies are left for garbage collection.
func (s *Store) Rebalance(ctx context.Context, ref Ref) (Ref, bool, error) {
	if s.Outdated(ref) {
		return ref, false, nil // Reencode places it anyway
	}
	ideal, err := erasure.Place(ref.ID, s.targets, len(ref.Placement))
	if err != nil {
		return ref, false, err
	}
	want := map[string]bool{}
	for _, id := range ideal {
		want[id] = true
	}
	used := map[string]bool{}
	for _, id := range ref.Placement {
		if want[id] {
			used[id] = true
		}
	}
	out := ref
	out.Placement = append([]string{}, ref.Placement...)
	moved := false
	for i, id := range ref.Placement {
		if want[id] {
			continue
		}
		dst := ""
		for _, c := range ideal {
			if !used[c] {
				dst = c
				break
			}
		}
		if dst == "" {
			break
		}
		st := s.stores[id]
		if st == nil {
			continue // Repair handles shards on storages that are gone
		}
		data, err := s.getShard(ctx, st, ref, i)
		if err != nil {
			continue
		}
		if err := s.putShard(ctx, dst, ref, i, data); err != nil {
			return out, moved, err
		}
		used[dst] = true
		out.Placement[i] = dst
		moved = true
	}
	return out, moved, nil
}

// Delete removes all shards of ref (best effort).
func (s *Store) Delete(ctx context.Context, ref Ref) error {
	var errs []error
	for i, id := range ref.Placement {
		if st := s.stores[id]; st != nil {
			errs = append(errs, st.Delete(ctx, s.shardName(ref.ID, ref.Gen, i)))
		}
	}
	return errors.Join(errs...)
}

func (s *Store) spareTarget(id []byte, used map[string]bool) string {
	order, _ := erasure.Place(id, s.targets, len(s.targets))
	for _, t := range order {
		if !used[t] {
			return t
		}
	}
	return ""
}

func (s *Store) decrypt(ref Ref, shards [][]byte) ([]byte, error) {
	codec, err := erasure.New(ref.K, len(ref.Placement)-ref.K)
	if err != nil {
		return nil, err
	}
	ct, err := codec.Decode(shards)
	if err != nil {
		return nil, err
	}
	pt, err := crypto.Open(s.dataKey.Derive("blob", ref.ID), ct, ref.ID)
	if err != nil {
		return nil, fmt.Errorf("blob %s: %w", ref.ID, err)
	}
	return pt, nil
}

// maxCombos bounds the search for a consistent shard set.
const maxCombos = 4096

// recoverMixed returns the plaintext and ciphertext of ref from shards
// (nil = unavailable). It tries all shards first, then every set of k of
// them, so it still works when shards of two encryptions of the blob are
// mixed: AEAD tells the right set apart. shards is not modified.
func (s *Store) recoverMixed(ref Ref, shards [][]byte) ([]byte, []byte, error) {
	codec, err := erasure.New(ref.K, len(ref.Placement)-ref.K)
	if err != nil {
		return nil, nil, err
	}
	key := s.dataKey.Derive("blob", ref.ID)
	try := func(set [][]byte) ([]byte, []byte, error) {
		ct, err := codec.Decode(set)
		if err != nil {
			return nil, nil, err
		}
		pt, err := crypto.Open(key, ct, ref.ID)
		if err != nil {
			return nil, nil, fmt.Errorf("blob %s: %w", ref.ID, err)
		}
		return pt, ct, nil
	}
	var have []int
	for i, sh := range shards {
		if sh != nil {
			have = append(have, i)
		}
	}
	pt, ct, firstErr := try(slices.Clone(shards))
	if firstErr == nil || len(have) <= ref.K {
		return pt, ct, firstErr
	}
	pick := make([]int, ref.K)
	for i := range pick {
		pick[i] = i
	}
	for n := 0; n < maxCombos; n++ {
		set := make([][]byte, len(shards))
		for _, p := range pick {
			set[have[p]] = shards[have[p]]
		}
		if pt, ct, err := try(set); err == nil {
			return pt, ct, nil
		}
		// next combination of k out of len(have)
		j := ref.K - 1
		for j >= 0 && pick[j] == len(have)-ref.K+j {
			j--
		}
		if j < 0 {
			break
		}
		pick[j]++
		for l := j + 1; l < ref.K; l++ {
			pick[l] = pick[l-1] + 1
		}
	}
	return nil, nil, firstErr
}

var errPartial = errors.New("blob: some shards unavailable")

// fetch downloads shards until want of them are good. Storages that
// answered fastest lately are asked first (data shards first among equal
// ones, they need no decoding). Each failure starts the next shard, and so
// does a storage that takes much longer than it usually does (a hedged
// read). With want = all shards it returns errPartial when at least K arrived.
func (s *Store) fetch(ctx context.Context, ref Ref, want int) ([][]byte, error) {
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()
	n := len(ref.Placement)
	order := make([]int, n)
	score := make([]time.Duration, n)
	for i, id := range ref.Placement {
		order[i] = i
		if st := s.stores[id]; st != nil {
			score[i] = backend.StatsOf(st).Score()
		} else {
			score[i] = time.Hour
		}
	}
	sort.SliceStable(order, func(a, b int) bool { return score[order[a]] < score[order[b]] })
	type result struct {
		i    int
		data []byte
		err  error
	}
	results := make(chan result, n)
	next := 0
	var slowest time.Duration // expected time of the slowest running read
	start := func() {
		i := order[next]
		next++
		slowest = max(slowest, score[i])
		st := s.stores[ref.Placement[i]]
		go func() {
			if st == nil {
				results <- result{i, nil, fmt.Errorf("storage %s not open", ref.Placement[i])}
				return
			}
			d, err := s.getShard(ctx, st, ref, i)
			results <- result{i, d, err}
		}()
	}
	for next < want && next < n {
		start()
	}
	hedge := time.NewTimer(hedgeAfter(slowest))
	defer hedge.Stop()
	shards := make([][]byte, n)
	good, running := 0, next
	var errs []error
	for running > 0 && good < want {
		var r result
		select {
		case r = <-results:
		case <-hedge.C:
			if next < n {
				start()
				running++
				hedge.Reset(hedgeAfter(slowest))
			}
			continue
		}
		running--
		if r.err == nil {
			shards[r.i] = r.data
			good++
			continue
		}
		errs = append(errs, fmt.Errorf("shard %d on %s: %w", r.i, ref.Placement[r.i], r.err))
		if next < n {
			start()
			running++
		}
	}
	switch {
	case good >= want:
		return shards, nil
	case good >= ref.K:
		return shards, errPartial
	default:
		return nil, fmt.Errorf("blob %s: %w: %w", ref.ID, erasure.ErrTooFewShards, errors.Join(errs...))
	}
}

// hedgeAfter is how long reads may run before one more shard is asked
// for: well past what the slowest of them usually takes.
func hedgeAfter(expected time.Duration) time.Duration {
	return max(2*expected, 2*time.Second)
}

func (s *Store) putShard(ctx context.Context, storeID string, ref Ref, i int, data []byte) error {
	st := s.stores[storeID]
	if st == nil {
		return fmt.Errorf("storage %s not open", storeID)
	}
	sum := sha256.Sum256(data)
	return st.Put(ctx, s.shardName(ref.ID, ref.Gen, i), append(sum[:], data...))
}

var errCorrupt = errors.New("shard checksum mismatch")

func (s *Store) getShard(ctx context.Context, st backend.Store, ref Ref, i int) ([]byte, error) {
	d, err := st.Get(ctx, s.shardName(ref.ID, ref.Gen, i))
	if err != nil {
		return nil, err
	}
	if len(d) < sha256.Size {
		return nil, errCorrupt
	}
	sum := sha256.Sum256(d[sha256.Size:])
	if !bytes.Equal(sum[:], d[:sha256.Size]) {
		return nil, errCorrupt
	}
	return d[sha256.Size:], nil
}
