package chunker

import (
	"bytes"
	"crypto/sha256"
	"io"
	"math/rand"
	"testing"

	"cloudsync/core/crypto"
)

var small = Params{Min: 1 << 10, Avg: 4 << 10, Max: 16 << 10}

func split(t *testing.T, data []byte, g *Gear) [][32]byte {
	t.Helper()
	c, err := New(bytes.NewReader(data), small, g)
	if err != nil {
		t.Fatal(err)
	}
	var out [][32]byte
	var joined []byte
	for {
		ch, err := c.Next()
		if err == io.EOF {
			break
		}
		if err != nil {
			t.Fatal(err)
		}
		if len(ch) > small.Max {
			t.Fatalf("chunk too big: %d", len(ch))
		}
		joined = append(joined, ch...)
		out = append(out, sha256.Sum256(ch))
	}
	if !bytes.Equal(joined, data) {
		t.Fatal("chunks do not add up to the input")
	}
	return out
}

func TestChunking(t *testing.T) {
	key, _ := crypto.NewKey()
	g := NewGear(key)
	data := make([]byte, 1<<20)
	rand.New(rand.NewSource(1)).Read(data)

	a := split(t, data, g)
	if n := len(a); n < 100 || n > 600 {
		t.Fatalf("unexpected chunk count %d for 1 MiB at 4 KiB avg", n)
	}
	if len(split(t, nil, g)) != 0 {
		t.Fatal("chunks for empty input")
	}

	// Insert bytes in the middle: most chunks must stay the same.
	edited := append(append(append([]byte{}, data[:500000]...), []byte("inserted")...), data[500000:]...)
	b := split(t, edited, g)
	set := map[[32]byte]bool{}
	for _, h := range a {
		set[h] = true
	}
	same := 0
	for _, h := range b {
		if set[h] {
			same++
		}
	}
	if same < len(a)-3 {
		t.Fatalf("only %d of %d chunks reused after a small insert", same, len(a))
	}

	// Another key gives other boundaries.
	k2, _ := crypto.NewKey()
	c := split(t, data, NewGear(k2))
	if len(c) > 0 && c[0] == a[0] {
		t.Fatal("boundaries do not depend on the key")
	}
}
