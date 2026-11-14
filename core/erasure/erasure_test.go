package erasure

import (
	"bytes"
	"crypto/rand"
	"errors"
	"fmt"
	"testing"
)

func TestEncodeDecodeAnyLoss(t *testing.T) {
	for _, km := range [][2]int{{1, 1}, {2, 1}, {3, 1}, {4, 2}, {3, 0}} {
		c, err := New(km[0], km[1])
		if err != nil {
			t.Fatal(err)
		}
		for _, size := range []int{0, 1, 7, 1000, 65537} {
			data := make([]byte, size)
			rand.Read(data)
			shards, err := c.Encode(data)
			if err != nil {
				t.Fatal(err)
			}
			// Drop every combination of up to M shards.
			for mask := 0; mask < 1<<c.N(); mask++ {
				lost := 0
				for i := 0; i < c.N(); i++ {
					if mask&(1<<i) != 0 {
						lost++
					}
				}
				if lost > c.M {
					continue
				}
				in := make([][]byte, c.N())
				for i := range in {
					if mask&(1<<i) == 0 {
						in[i] = append([]byte{}, shards[i]...)
					}
				}
				got, err := c.Decode(in)
				if err != nil || !bytes.Equal(got, data) {
					t.Fatalf("k=%d m=%d size=%d mask=%b: %v", c.K, c.M, size, mask, err)
				}
			}
			if c.M > 0 {
				in := make([][]byte, c.N())
				copy(in, shards)
				for i := 0; i <= c.M; i++ {
					in[i] = nil
				}
				if _, err := c.Decode(in); !errors.Is(err, ErrTooFewShards) {
					t.Fatalf("decoded with too few shards: %v", err)
				}
			}
		}
	}
}

func TestReconstruct(t *testing.T) {
	c, _ := New(3, 1)
	shards, _ := c.Encode([]byte("some data to protect"))
	parity := append([]byte{}, shards[3]...)
	shards[3] = nil
	if err := c.Reconstruct(shards); err != nil || !bytes.Equal(shards[3], parity) {
		t.Fatalf("parity not rebuilt: %v", err)
	}
}

func TestPlace(t *testing.T) {
	targets := []Target{
		{"mega1", "mega"}, {"mega2", "mega"}, {"gd", "drive"}, {"s3", "s3"},
	}
	// 3 shards over 4 storages, 3 domains: never two Mega accounts.
	counts := map[string]int{}
	for i := 0; i < 2000; i++ {
		id := []byte(fmt.Sprint(i))
		p, err := Place(id, targets, 3)
		if err != nil {
			t.Fatal(err)
		}
		again, _ := Place(id, targets, 3)
		if fmt.Sprint(p) != fmt.Sprint(again) {
			t.Fatal("placement not stable")
		}
		if MaxPerDomain(p, targets) != 1 {
			t.Fatalf("two shards in one domain: %v", p)
		}
		for _, id := range p {
			counts[id]++
		}
	}
	// drive and s3 are in every placement, the two Mega accounts share the rest.
	if counts["gd"] != 2000 || counts["s3"] != 2000 || counts["mega1"] < 800 || counts["mega2"] < 800 {
		t.Fatalf("bad spread: %v", counts)
	}
	// 4 shards: a domain must be reused, and that is all right.
	p, _ := Place([]byte("x"), targets, 4)
	if len(p) != 4 || MaxPerDomain(p, targets) != 2 {
		t.Fatalf("%v", p)
	}
	if _, err := Place([]byte("x"), targets, 5); err == nil {
		t.Fatal("placed 5 shards on 4 storages")
	}
}
