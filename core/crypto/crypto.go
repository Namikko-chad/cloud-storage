// Package crypto holds the primitives every other package builds on:
// a 32-byte key type, purpose-bound subkeys (HKDF-SHA256), authenticated
// encryption (XChaCha20-Poly1305) and keyed object names (HMAC-SHA256).
package crypto

import (
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"encoding/binary"
	"encoding/hex"
	"errors"
	"hash"
	"io"

	"golang.org/x/crypto/chacha20poly1305"
	"golang.org/x/crypto/hkdf"
)

const KeySize = 32

// Key is a symmetric key.
type Key [KeySize]byte

// ErrDecrypt is returned when a ciphertext fails authentication
// (wrong key, wrong associated data or tampered data).
var ErrDecrypt = errors.New("crypto: decryption failed")

// NewKey returns a random key.
func NewKey() (Key, error) {
	var k Key
	_, err := io.ReadFull(rand.Reader, k[:])
	return k, err
}

// Derive returns a subkey of k bound to purpose and id, so that keys used
// for different things never coincide.
func (k Key) Derive(purpose string, id []byte) Key {
	var out Key
	r := hkdf.New(sha256.New, k[:], id, []byte("cloudsync/"+purpose))
	if _, err := io.ReadFull(r, out[:]); err != nil {
		panic(err) // hkdf only fails when asked for too much output
	}
	return out
}

// MAC returns HMAC-SHA256 of data under k.
func (k Key) MAC(data ...[]byte) []byte {
	m := hmac.New(sha256.New, k[:])
	for _, d := range data {
		m.Write(d)
	}
	return m.Sum(nil)
}

// NewMAC returns a streaming HMAC-SHA256 under k.
func (k Key) NewMAC() hash.Hash { return hmac.New(sha256.New, k[:]) }

// Name returns a hex object name for data that reveals nothing without k.
func (k Key) Name(data ...[]byte) string {
	return hex.EncodeToString(k.MAC(data...))
}

// Overhead is the number of bytes Seal adds to the plaintext.
const Overhead = chacha20poly1305.NonceSizeX + chacha20poly1305.Overhead

// Seal encrypts and authenticates plaintext, binding it to ad.
// The output is nonce || ciphertext.
func Seal(k Key, plaintext, ad []byte) ([]byte, error) {
	aead, err := chacha20poly1305.NewX(k[:])
	if err != nil {
		return nil, err
	}
	out := make([]byte, chacha20poly1305.NonceSizeX, Overhead+len(plaintext))
	if _, err := io.ReadFull(rand.Reader, out); err != nil {
		return nil, err
	}
	return aead.Seal(out, out, plaintext, ad), nil
}

// SealDeterministic is Seal with a nonce derived from k, plaintext and ad
// (SIV style): the same input always gives the same output. Use it for
// content-addressed objects, whose stored copies must not differ when the
// same content is written twice. It reveals only that two ciphertexts under
// k are equal; Open reads it like any Seal output.
func SealDeterministic(k Key, plaintext, ad []byte) ([]byte, error) {
	aead, err := chacha20poly1305.NewX(k[:])
	if err != nil {
		return nil, err
	}
	var n [8]byte
	binary.BigEndian.PutUint64(n[:], uint64(len(ad)))
	nonce := k.Derive("siv-nonce", nil).MAC(n[:], ad, plaintext)[:chacha20poly1305.NonceSizeX]
	out := make([]byte, chacha20poly1305.NonceSizeX, Overhead+len(plaintext))
	copy(out, nonce)
	return aead.Seal(out, out, plaintext, ad), nil
}

// Open reverses Seal.
func Open(k Key, sealed, ad []byte) ([]byte, error) {
	aead, err := chacha20poly1305.NewX(k[:])
	if err != nil {
		return nil, err
	}
	if len(sealed) < Overhead {
		return nil, ErrDecrypt
	}
	n := chacha20poly1305.NonceSizeX
	pt, err := aead.Open(nil, sealed[:n], sealed[n:], ad)
	if err != nil {
		return nil, ErrDecrypt
	}
	return pt, nil
}

// RandomID returns n random bytes, hex encoded.
func RandomID(n int) string {
	b := make([]byte, n)
	if _, err := io.ReadFull(rand.Reader, b); err != nil {
		panic(err)
	}
	return hex.EncodeToString(b)
}
