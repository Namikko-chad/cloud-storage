package secrets

import (
	"crypto/ed25519"
	"crypto/rand"
	"encoding/json"
	"encoding/pem"
	"strings"
	"testing"

	"golang.org/x/crypto/ssh"

	"cloudsync/core/crypto"
	"cloudsync/core/index"
)

func TestEVMAddress(t *testing.T) {
	for priv, addr := range map[string]string{
		"0x4c0883a69102937d6231471b5dbb6204fe5129617082792ae468d01a3f362318": "0x2c7536E3605D9C16a7a3D7b1898e529396a65c23",
		"0000000000000000000000000000000000000000000000000000000000000001":   "0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf",
	} {
		k, err := Web3Public(NetworkEVM, " "+priv+"\n")
		if err != nil {
			t.Fatal(err)
		}
		if k.Address != addr || !strings.HasPrefix(k.PublicKey, "0x04") || len(k.PublicKey) != 132 {
			t.Fatalf("%s: %+v", priv, k)
		}
	}
	for _, bad := range []string{"", "0x12", strings.Repeat("0", 64), strings.Repeat("f", 64), "zz" + strings.Repeat("1", 62)} {
		if _, err := Web3Public(NetworkEVM, bad); err == nil {
			t.Fatalf("%q accepted", bad)
		}
	}
}

func TestBase58(t *testing.T) {
	if got := base58Encode([]byte("Hello World!")); got != "2NEpo7TZRRrLZSi2U" {
		t.Fatal(got)
	}
	if got := base58Encode([]byte{0, 0, 1}); got != "112" {
		t.Fatal(got)
	}
	b, err := base58Decode("112")
	if err != nil || string(b) != "\x00\x00\x01" {
		t.Fatal(b, err)
	}
}

func TestSolana(t *testing.T) {
	pub, priv, _ := ed25519.GenerateKey(rand.Reader)
	want := base58Encode(pub)
	nums := make([]int, len(priv))
	for i, c := range priv {
		nums[i] = int(c)
	}
	arr, _ := json.Marshal(nums)
	for _, in := range []string{base58Encode(priv), string(arr), base58Encode(priv.Seed())} {
		k, err := Web3Public(NetworkSolana, in)
		if err != nil || k.Address != want {
			t.Fatalf("%q: %+v %v", in, k, err)
		}
	}
	bad := append([]byte{}, priv...)
	bad[40] ^= 1
	if _, err := Web3Public(NetworkSolana, base58Encode(bad)); err == nil {
		t.Fatal("mismatched keypair accepted")
	}
}

func TestSSH(t *testing.T) {
	pub, priv, _ := ed25519.GenerateKey(rand.Reader)
	sp, _ := ssh.NewPublicKey(pub)
	want := strings.TrimSpace(string(ssh.MarshalAuthorizedKey(sp)))

	block, err := ssh.MarshalPrivateKey(priv, "")
	if err != nil {
		t.Fatal(err)
	}
	k, err := SSHPublic(string(pem.EncodeToMemory(block)), "", "me@laptop")
	if err != nil || k.AuthorizedKey != want+" me@laptop" || k.Type != "ssh-ed25519" || k.Fingerprint != ssh.FingerprintSHA256(sp) {
		t.Fatalf("%+v %v", k, err)
	}

	enc, _ := ssh.MarshalPrivateKeyWithPassphrase(priv, "", []byte("secret"))
	text := string(pem.EncodeToMemory(enc))
	// OpenSSH keeps the public key in the clear: no passphrase needed.
	if k, err := SSHPublic(text, "", ""); err != nil || k.AuthorizedKey != want {
		t.Fatalf("encrypted, no passphrase: %+v %v", k, err)
	}
	if k, err := SSHPublic(text, "secret", ""); err != nil || k.AuthorizedKey != want {
		t.Fatalf("encrypted: %+v %v", k, err)
	}
	if _, err := SSHPublic(text, "wrong", ""); err == nil {
		t.Fatal("wrong passphrase accepted")
	}
	if _, err := SSHPublic("not a key", "", ""); err == nil {
		t.Fatal("garbage accepted")
	}
}

func TestSealOpen(t *testing.T) {
	master, _ := crypto.NewKey()
	k := NewKeys(master)
	m := Meta{Kind: KindPassword, Title: "Mail"}
	d := Data{Password: "hunter2", Notes: "recovery: 1234"}
	if err := Prepare(&m, &d); err != nil {
		t.Fatal(err)
	}
	ch, err := k.SealEntry("e1", m, d)
	if err != nil {
		t.Fatal(err)
	}
	for _, part := range [][]byte{ch.Meta, ch.Data} {
		if strings.Contains(string(part), "hunter2") || strings.Contains(string(part), "Mail") {
			t.Fatal("plaintext in a sealed part")
		}
	}
	s := index.Secret{ID: "e1", SealedAs: "e1", Meta: ch.Meta, Data: ch.Data}
	e, err := k.OpenEntry(s, false)
	if err != nil || e.Title != "Mail" || e.Data != nil {
		t.Fatalf("%+v %v", e, err)
	}
	if e, err = k.OpenEntry(s, true); err != nil || e.Data.Password != "hunter2" {
		t.Fatalf("%+v %v", e, err)
	}
	// Sealed for another record: rejected.
	s.SealedAs = "e2"
	if _, err := k.OpenEntry(s, false); err == nil {
		t.Fatal("record moved to another id opened")
	}
	if err := PrepareGroup(&GroupMeta{Name: "x", Icon: []byte("not an image")}); err == nil {
		t.Fatal("non-image icon accepted")
	}
}
