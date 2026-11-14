package index

import (
	"reflect"
	"testing"
)

func TestSecretFold(t *testing.T) {
	put := func(dev string, seq, lam uint64, id, parent, meta string) Op {
		return Op{Device: dev, Seq: seq, Lamport: lam, Kind: OpSecret, Parent: parent,
			Secret: &SecretChange{ID: id, Meta: []byte(meta)}}
	}
	ops := []Op{
		put("a", 1, 1, "x", "", "v1"),
		put("a", 2, 2, "x", "a.1", "a-edit"),
		put("b", 1, 2, "x", "a.1", "b-edit"), // concurrent with a.2
		{Device: "a", Seq: 3, Lamport: 3, Kind: OpSecret, Parent: "a.1", Secret: &SecretChange{ID: "x", Deleted: true}},
		put("b", 2, 3, "y", "", "y1"),
		{Device: "b", Seq: 3, Lamport: 4, Kind: OpSecret, Parent: "b.2", Secret: &SecretChange{ID: "y", Deleted: true}},
	}
	in := New()
	in.Add(ops...)
	got := in.Secrets()
	if len(got) != 2 || got[0].ID != "x" || string(got[0].Meta) != "a-edit" ||
		got[1].ConflictOf != "x" || got[1].SealedAs != "x" || string(got[1].Meta) != "b-edit" {
		t.Fatalf("%+v", got)
	}
	// Any arrival order gives the same records.
	rev := New()
	for i := len(ops) - 1; i >= 0; i-- {
		rev.Add(ops[i])
	}
	if !reflect.DeepEqual(rev.Secrets(), got) {
		t.Fatalf("order matters:\n%+v\n%+v", rev.Secrets(), got)
	}
	if len(in.List("/")) != 0 {
		t.Fatal("secret ops show up in the file tree")
	}
}
