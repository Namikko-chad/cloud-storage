// Package erasure splits a blob into k data + m parity shards
// (Reed-Solomon; m=1 is RAID 5) and picks which storage holds each shard.
package erasure

import (
	"crypto/sha256"
	"encoding/binary"
	"errors"
	"fmt"
	"sort"

	"github.com/klauspost/reedsolomon"
)

// ErrTooFewShards means fewer than k shards survived.
var ErrTooFewShards = errors.New("erasure: not enough shards to reconstruct")

// Codec encodes with fixed k and m.
type Codec struct {
	K, M int
	enc  reedsolomon.Encoder
}

// New returns a codec for k data and m parity shards.
func New(k, m int) (*Codec, error) {
	if k < 1 || m < 0 {
		return nil, fmt.Errorf("erasure: bad k=%d m=%d", k, m)
	}
	c := &Codec{K: k, M: m}
	if m > 0 {
		enc, err := reedsolomon.New(k, m)
		if err != nil {
			return nil, err
		}
		c.enc = enc
	}
	return c, nil
}

// N is the total number of shards.
func (c *Codec) N() int { return c.K + c.M }

// Encode returns N shards of equal size. The original length is stored in
// the data, so Decode needs nothing else.
func (c *Codec) Encode(data []byte) ([][]byte, error) {
	buf := binary.BigEndian.AppendUint64(make([]byte, 0, 8+len(data)), uint64(len(data)))
	buf = append(buf, data...)
	size := (len(buf) + c.K - 1) / c.K
	shards := make([][]byte, c.N())
	for i := range shards {
		shards[i] = make([]byte, size)
		if i < c.K && i*size < len(buf) {
			copy(shards[i], buf[i*size:])
		}
	}
	if c.enc != nil {
		if err := c.enc.Encode(shards); err != nil {
			return nil, err
		}
	}
	return shards, nil
}

// Decode rebuilds the data. Missing shards are nil; at least K are needed.
// It reconstructs missing shards in place.
func (c *Codec) Decode(shards [][]byte) ([]byte, error) {
	if len(shards) != c.N() {
		return nil, fmt.Errorf("erasure: got %d shards, want %d", len(shards), c.N())
	}
	have, dataOK := 0, true
	for i, s := range shards {
		if s != nil {
			have++
		} else if i < c.K {
			dataOK = false
		}
	}
	if have < c.K {
		return nil, ErrTooFewShards
	}
	if !dataOK {
		if c.enc == nil {
			return nil, ErrTooFewShards
		}
		if err := c.enc.ReconstructData(shards); err != nil {
			return nil, fmt.Errorf("erasure: %w", err)
		}
	}
	var buf []byte
	for _, s := range shards[:c.K] {
		buf = append(buf, s...)
	}
	if len(buf) < 8 {
		return nil, errors.New("erasure: shard too short")
	}
	n := binary.BigEndian.Uint64(buf)
	if n > uint64(len(buf)-8) {
		return nil, errors.New("erasure: bad length")
	}
	return buf[8 : 8+n], nil
}

// Reconstruct rebuilds every missing shard (data and parity), for repair.
func (c *Codec) Reconstruct(shards [][]byte) error {
	if c.enc == nil {
		for i, s := range shards {
			if s == nil {
				return fmt.Errorf("erasure: shard %d lost and there is no parity", i)
			}
		}
		return nil
	}
	return c.enc.Reconstruct(shards)
}

// Target is a storage a shard can go to.
type Target struct {
	ID     string
	Domain string // failure domain (provider); shards prefer distinct domains
}

// Place picks n distinct targets for the blob with the given id.
// The order is stable for the same inputs (rendezvous hashing), load is
// spread evenly when there are more targets than shards, and targets in a
// domain not used yet are preferred so that one provider outage takes out
// as few shards as possible.
func Place(id []byte, targets []Target, n int) ([]string, error) {
	if len(targets) < n {
		return nil, fmt.Errorf("erasure: need %d storages, have %d", n, len(targets))
	}
	type scored struct {
		Target
		score uint64
	}
	all := make([]scored, len(targets))
	for i, t := range targets {
		h := sha256.Sum256(append(append([]byte{}, id...), t.ID...))
		all[i] = scored{t, binary.BigEndian.Uint64(h[:8])}
	}
	sort.Slice(all, func(i, j int) bool { return all[i].score > all[j].score })

	out := make([]string, 0, n)
	used := map[string]bool{}
	domains := map[string]int{}
	// Round by round: in each round a domain gets at most one more shard.
	for round := 1; len(out) < n; round++ {
		for _, t := range all {
			if len(out) == n {
				break
			}
			if used[t.ID] || domains[t.Domain] >= round {
				continue
			}
			used[t.ID] = true
			domains[t.Domain]++
			out = append(out, t.ID)
		}
	}
	return out, nil
}

// MaxPerDomain returns the largest number of targets that share one
// domain among the chosen ids: losing that provider loses that many shards.
func MaxPerDomain(ids []string, targets []Target) int {
	dom := map[string]string{}
	for _, t := range targets {
		dom[t.ID] = t.Domain
	}
	count, max := map[string]int{}, 0
	for _, id := range ids {
		count[dom[id]]++
		if count[dom[id]] > max {
			max = count[dom[id]]
		}
	}
	return max
}
