package crypto

import (
	"bytes"
	"errors"
	"testing"
)

func TestSealOpen(t *testing.T) {
	k, _ := NewKey()
	msg := []byte("hello")
	sealed, err := Seal(k, msg, []byte("ad"))
	if err != nil {
		t.Fatal(err)
	}
	if len(sealed) != len(msg)+Overhead {
		t.Fatalf("len %d", len(sealed))
	}
	got, err := Open(k, sealed, []byte("ad"))
	if err != nil || !bytes.Equal(got, msg) {
		t.Fatalf("open: %v %q", err, got)
	}
	if _, err := Open(k, sealed, []byte("other")); !errors.Is(err, ErrDecrypt) {
		t.Fatal("wrong ad accepted")
	}
	k2, _ := NewKey()
	if _, err := Open(k2, sealed, []byte("ad")); !errors.Is(err, ErrDecrypt) {
		t.Fatal("wrong key accepted")
	}
	sealed[len(sealed)-1] ^= 1
	if _, err := Open(k, sealed, []byte("ad")); !errors.Is(err, ErrDecrypt) {
		t.Fatal("tampered data accepted")
	}
}

func TestDerive(t *testing.T) {
	k, _ := NewKey()
	a := k.Derive("chunk", []byte("1"))
	if a != k.Derive("chunk", []byte("1")) {
		t.Fatal("not deterministic")
	}
	if a == k.Derive("chunk", []byte("2")) || a == k.Derive("name", []byte("1")) {
		t.Fatal("subkeys collide")
	}
}
