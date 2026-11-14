package engine

import (
	"bytes"
	"context"
	"testing"
	"time"

	"cloudsync/core/erasure"
)

func TestWritable(t *testing.T) {
	ts := []erasure.Target{{ID: "a", Domain: "a"}, {ID: "b", Domain: "b"}, {ID: "c", Domain: "c"}}
	// k=2 n=3 on 3 storages: every blob puts size/2 on each one.
	if got := writable(ts, 2, 3, map[string]int64{"a": 100, "b": 200, "c": 300}); got != 200 {
		t.Fatalf("got %d, want 200", got)
	}
	// A storage that does not report is unlimited.
	if got := writable(ts, 2, 3, map[string]int64{"b": 200}); got != 400 {
		t.Fatalf("got %d, want 400", got)
	}
	if got := writable(ts, 2, 3, nil); got != -1 {
		t.Fatalf("got %d, want -1", got)
	}
	// 4 storages, n=2: each gets about half of the blobs.
	ts = append(ts, erasure.Target{ID: "d", Domain: "d"})
	got := writable(ts, 1, 2, map[string]int64{"a": 1000, "b": 1000, "c": 1000, "d": 1000})
	if got < 1800 || got > 2200 {
		t.Fatalf("got %d, want about 2000", got)
	}
}

func TestSpace(t *testing.T) {
	ctx := context.Background()
	w := newWorld(t) // k=2 m=1 over mega1, mega2, gd, s3
	for _, id := range []string{"mega1", "mega2", "gd"} {
		w.mem[id].Quota = 10 << 20
	}
	e := w.device("laptop")
	data := random(200<<10, 7)
	if _, err := e.PutFile(ctx, "/a.bin", bytes.NewReader(data), time.Now()); err != nil {
		t.Fatal(err)
	}
	sp := e.Space(ctx)
	if sp.Files != int64(len(data)) {
		t.Fatalf("files %d, want %d", sp.Files, len(data))
	}
	var stored int64
	for _, b := range sp.Backends {
		stored += b.Stored
		if known := b.ID != "s3"; b.Known != known {
			t.Fatalf("%s: known=%v", b.ID, b.Known)
		}
	}
	// n/k = 3/2 of the data, plus a little per block.
	if want := int64(len(data)) * 3 / 2; stored < want || stored > want+want/20 {
		t.Fatalf("stored %d, want about %d", stored, want)
	}
	// Both Megas share a failure domain, so gd and s3 get a shard of every
	// blob: gd (10 MiB, s3 unlimited) fills first after 2 x its free space.
	var gd int64
	for _, b := range sp.Backends {
		if b.ID == "gd" {
			gd = b.Free
		}
	}
	if sp.Writable < 2*gd-1024 || sp.Writable > 2*gd {
		t.Fatalf("writable %d, want about %d", sp.Writable, 2*gd)
	}
}
