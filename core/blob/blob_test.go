package blob

import (
	"bytes"
	"context"
	"crypto/rand"
	"testing"

	"cloudsync/core/backend"
	"cloudsync/core/crypto"
	"cloudsync/core/erasure"
)

type env struct {
	mem     map[string]*backend.MemStore
	stores  map[string]backend.Store
	targets []erasure.Target
	key     crypto.Key
}

func newEnv(ids ...string) *env {
	e := &env{mem: map[string]*backend.MemStore{}, stores: map[string]backend.Store{}}
	e.key, _ = crypto.NewKey()
	for _, id := range ids {
		m := backend.NewMemStore(id)
		e.mem[id], e.stores[id] = m, m
		e.targets = append(e.targets, erasure.Target{ID: id, Domain: id})
	}
	return e
}

func (e *env) blobs(t *testing.T, k, m int) *Store {
	s, err := New(e.key, k, m, e.targets, e.stores)
	if err != nil {
		t.Fatal(err)
	}
	return s
}

func TestPutGetWithOutage(t *testing.T) {
	ctx := context.Background()
	e := newEnv("a", "b", "c")
	s := e.blobs(t, 2, 1)
	data := make([]byte, 100000)
	rand.Read(data)
	ref, err := s.Put(ctx, data)
	if err != nil || len(ref.Missing) != 0 {
		t.Fatal(err, ref.Missing)
	}
	for id, m := range e.mem {
		for _, obj := range m.Objects() {
			if bytes.Contains(obj, data[:64]) {
				t.Fatalf("plaintext on %s", id)
			}
		}
	}
	for _, off := range []string{"", "a", "b", "c"} {
		if off != "" {
			e.mem[off].SetOffline(true)
		}
		got, err := s.Get(ctx, ref)
		if err != nil || !bytes.Equal(got, data) {
			t.Fatalf("offline %q: %v", off, err)
		}
		if off != "" {
			e.mem[off].SetOffline(false)
		}
	}
	e.mem["a"].SetOffline(true)
	e.mem["b"].SetOffline(true)
	if _, err := s.Get(ctx, ref); err == nil {
		t.Fatal("read with two of three storages down")
	}
}

func TestCorruptShardIgnored(t *testing.T) {
	ctx := context.Background()
	e := newEnv("a", "b", "c")
	s := e.blobs(t, 2, 1)
	ref, _ := s.Put(ctx, []byte("payload"))
	name := s.ShardName(ref.ID, 0)
	obj, _ := e.mem[ref.Placement[0]].Get(ctx, name)
	obj[len(obj)-1] ^= 0xff
	e.mem[ref.Placement[0]].Put(ctx, name, obj)
	got, err := s.Get(ctx, ref)
	if err != nil || string(got) != "payload" {
		t.Fatalf("%v %q", err, got)
	}
}

func TestDegradedWriteAndRepair(t *testing.T) {
	ctx := context.Background()
	e := newEnv("a", "b", "c")
	s := e.blobs(t, 2, 1)
	e.mem["c"].SetOffline(true)
	ref, err := s.Put(ctx, []byte("written while c was down"))
	if err != nil || len(ref.Missing) != 1 {
		t.Fatalf("degraded write: %v %v", err, ref.Missing)
	}
	e.mem["c"].SetOffline(false)
	fixed, changed, err := s.Repair(ctx, ref)
	if err != nil || !changed || len(fixed.Missing) != 0 {
		t.Fatalf("repair: %v %v %v", err, changed, fixed.Missing)
	}
	// Now any single storage may go.
	e.mem["a"].SetOffline(true)
	if got, err := s.Get(ctx, fixed); err != nil || string(got) != "written while c was down" {
		t.Fatal(err)
	}
	e.mem["a"].SetOffline(false)
	if _, changed, _ := s.Repair(ctx, fixed); changed {
		t.Fatal("healthy blob repaired")
	}
	e.mem["a"].SetOffline(true)
	e.mem["b"].SetOffline(true)
	if _, err := s.Put(ctx, []byte("x")); err == nil {
		t.Fatal("write with fewer than k storages")
	}
}

func TestMoveOffRemovedStorage(t *testing.T) {
	ctx := context.Background()
	e := newEnv("a", "b", "c", "d")
	s := e.blobs(t, 2, 1)
	ref, _ := s.Put(ctx, []byte("move me"))
	gone := ref.Placement[0]
	// Storage removed from config: still readable while it lives, then wiped.
	var targets []erasure.Target
	for _, tg := range e.targets {
		if tg.ID != gone {
			targets = append(targets, tg)
		}
	}
	s2, err := New(e.key, 2, 1, targets, e.stores)
	if err != nil {
		t.Fatal(err)
	}
	moved, changed, err := s2.Repair(ctx, ref)
	if err != nil || !changed {
		t.Fatal(err)
	}
	for _, id := range moved.Placement {
		if id == gone {
			t.Fatal("shard still on removed storage")
		}
	}
	e.mem[gone].Wipe()
	e.mem[moved.Placement[1]].SetOffline(true)
	if got, err := s2.Get(ctx, moved); err != nil || string(got) != "move me" {
		t.Fatal(err)
	}
}

func TestPutTwiceSameShards(t *testing.T) {
	ctx := context.Background()
	e := newEnv("a", "b", "c")
	s := e.blobs(t, 2, 1)
	data := []byte("same content written by two devices")
	ref, _ := s.Put(ctx, data)
	before := map[string]string{}
	for _, sh := range s.Shards(ref) {
		d, _ := e.stores[sh.Store].Get(ctx, sh.Name)
		before[sh.Store+sh.Name] = string(d)
	}
	if _, err := s.Put(ctx, data); err != nil {
		t.Fatal(err)
	}
	for _, sh := range s.Shards(ref) {
		d, _ := e.stores[sh.Store].Get(ctx, sh.Name)
		if string(d) != before[sh.Store+sh.Name] {
			t.Fatalf("shard on %s changed on a second write", sh.Store)
		}
	}
}

// Old versions sealed blobs with a random nonce, so two writes of one blob
// could leave shards of two encodings under the same names.
func TestMixedShardsRecovered(t *testing.T) {
	ctx := context.Background()
	e := newEnv("a", "b", "c", "d", "e")
	s := e.blobs(t, 2, 3)
	data := make([]byte, 5000)
	rand.Read(data)
	ref, err := s.Put(ctx, data)
	if err != nil {
		t.Fatal(err)
	}
	// Overwrite data shard 0 and parity shard 2 with another encryption.
	ct, _ := crypto.Seal(s.dataKey.Derive("blob", ref.ID), data, ref.ID)
	other, _ := s.codec.Encode(ct)
	for _, i := range []int{0, 2} {
		if err := s.putShard(ctx, ref.Placement[i], ref, i, other[i]); err != nil {
			t.Fatal(err)
		}
	}
	got, err := s.Get(ctx, ref)
	if err != nil || !bytes.Equal(got, data) {
		t.Fatalf("get: %v", err)
	}
	fixed, changed, err := s.Repair(ctx, ref)
	if err != nil || !changed {
		t.Fatalf("repair: changed=%v err=%v", changed, err)
	}
	// Now the first k shards alone decode again.
	shards, err := s.fetch(ctx, fixed, fixed.K)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := s.decrypt(fixed, shards); err != nil {
		t.Fatalf("after repair: %v", err)
	}
	if _, changed, _ := s.Repair(ctx, fixed); changed {
		t.Fatal("second repair changed something")
	}
}
