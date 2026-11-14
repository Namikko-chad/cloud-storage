// Package chunker splits a stream into content-defined chunks (FastCDC).
// An edit in the middle of a file changes only the chunks around it, so
// only those are uploaded again. The gear table is derived from a key, so
// chunk sizes do not reveal which known file is stored.
package chunker

import (
	"encoding/binary"
	"errors"
	"io"
	"math/bits"

	"cloudsync/core/crypto"
)

// Params are chunk size limits in bytes.
type Params struct {
	Min, Avg, Max int
}

// Default gives ~4 MiB chunks: small enough for partial downloads, big
// enough to keep the number of objects per file low.
var Default = Params{Min: 1 << 20, Avg: 4 << 20, Max: 16 << 20}

// Gear is a keyed table of 256 random words.
type Gear [256]uint64

// NewGear derives the gear table from key.
func NewGear(key crypto.Key) *Gear {
	var g Gear
	k := key.Derive("chunker-gear", nil)
	for i := 0; i < 256; i += 4 {
		b := k.MAC([]byte{byte(i)})
		for j := 0; j < 4; j++ {
			g[i+j] = binary.LittleEndian.Uint64(b[j*8:])
		}
	}
	return &g
}

// Chunker reads chunks from r.
type Chunker struct {
	r            io.Reader
	p            Params
	g            *Gear
	maskS, maskL uint64
	buf          []byte
	start, end   int
	eof          bool
}

// New returns a chunker over r.
func New(r io.Reader, p Params, g *Gear) (*Chunker, error) {
	if p.Min < 64 || p.Avg <= p.Min || p.Max <= p.Avg {
		return nil, errors.New("chunker: bad params")
	}
	b := bits.Len(uint(p.Avg)) - 1
	return &Chunker{
		r: r, p: p, g: g,
		maskS: ^uint64(0) << (64 - (b + 1)), // harder to match before Avg
		maskL: ^uint64(0) << (64 - (b - 1)), // easier after Avg
		buf:   make([]byte, 2*p.Max),
	}, nil
}

// Next returns the next chunk, or io.EOF at the end. The slice is only
// valid until the next call.
func (c *Chunker) Next() ([]byte, error) {
	if err := c.fill(); err != nil {
		return nil, err
	}
	data := c.buf[c.start:c.end]
	if len(data) == 0 {
		return nil, io.EOF
	}
	n := c.cut(data)
	c.start += n
	return data[:n], nil
}

func (c *Chunker) fill() error {
	if c.end-c.start >= c.p.Max || c.eof {
		return nil
	}
	copy(c.buf, c.buf[c.start:c.end])
	c.end -= c.start
	c.start = 0
	for c.end < len(c.buf) && !c.eof {
		n, err := c.r.Read(c.buf[c.end:])
		c.end += n
		if errors.Is(err, io.EOF) {
			c.eof = true
		} else if err != nil {
			return err
		}
	}
	return nil
}

func (c *Chunker) cut(data []byte) int {
	if len(data) <= c.p.Min {
		return len(data)
	}
	n := len(data)
	if n > c.p.Max {
		n = c.p.Max
	}
	avg := c.p.Avg
	if n < avg {
		avg = n
	}
	var h uint64
	i := c.p.Min
	for ; i < avg; i++ {
		h = h<<1 + c.g[data[i]]
		if h&c.maskS == 0 {
			return i + 1
		}
	}
	for ; i < n; i++ {
		h = h<<1 + c.g[data[i]]
		if h&c.maskL == 0 {
			return i + 1
		}
	}
	return n
}
