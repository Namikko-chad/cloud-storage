// Package vault stores the whole configuration (master key, erasure
// settings, storage accounts and their credentials, known devices) in one
// file encrypted with a key derived from a password.
//
// File layout:
//
//	magic "CSVAULT\x01" | argon2 time u32 | memory KiB u32 | threads u8 | salt [16]
//	| XChaCha20-Poly1305(key, JSON config, ad = everything before it)
package vault

import (
	"bytes"
	"crypto/rand"
	"crypto/sha256"
	"encoding/binary"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"sync"
	"time"

	"golang.org/x/crypto/argon2"

	"cloudsync/core/crypto"
)

var magic = []byte("CSVAULT\x01")

const (
	saltSize   = 16
	headerSize = 8 + 4 + 4 + 1 + saltSize
)

var (
	ErrBadPassword = errors.New("vault: wrong password or corrupted file")
	ErrFormat      = errors.New("vault: not a vault file")
)

// KDFParams are the Argon2id cost parameters.
type KDFParams struct {
	Time    uint32
	Memory  uint32 // KiB
	Threads uint8
}

// DefaultKDF is strong enough for a password and still fine on phones.
var DefaultKDF = KDFParams{Time: 3, Memory: 64 * 1024, Threads: 4}

// Config is the decrypted content of the vault.
type Config struct {
	VaultID      string    `json:"vault_id"`
	Version      uint64    `json:"version"` // bumped on every change; newest copy wins
	MasterKey    []byte    `json:"master_key"`
	DataShards   int       `json:"data_shards"`   // k
	ParityShards int       `json:"parity_shards"` // m: how many storages may be lost
	Backends     []Backend `json:"backends"`
	Devices      []Device  `json:"devices"`
}

// Backend is one storage account. Several backends may share a Type
// (two Mega accounts): ID is what identifies a backend everywhere.
type Backend struct {
	ID     string `json:"id"`
	Name   string `json:"name"`
	Type   string `json:"type"`   // rclone backend name: drive, mega, s3, ...
	Domain string `json:"domain"` // failure domain; defaults to Type
	Root   string `json:"root"`   // folder inside the account
	// Account is who the storage signs in as (e-mail, login), for display
	// and to refuse a second storage on the same account. May be empty.
	Account string `json:"account,omitempty"`
	// Params are rclone options for this backend. Password options are
	// stored obscured, as rclone expects them.
	Params   map[string]string `json:"params"`
	Disabled bool              `json:"disabled,omitempty"`
}

// FailureDomain returns Domain, or Type when Domain is empty.
func (b Backend) FailureDomain() string {
	if b.Domain != "" {
		return b.Domain
	}
	return b.Type
}

// Device is a device that has joined the vault.
type Device struct {
	ID       string    `json:"id"`
	Name     string    `json:"name"`
	Platform string    `json:"platform"`
	Added    time.Time `json:"added"`
}

// Key returns the master key.
func (c *Config) Key() crypto.Key {
	var k crypto.Key
	copy(k[:], c.MasterKey)
	return k
}

// Backend returns the backend with the given id.
func (c *Config) Backend(id string) (Backend, bool) {
	for _, b := range c.Backends {
		if b.ID == id {
			return b, true
		}
	}
	return Backend{}, false
}

// ActiveBackends returns the backends that are not disabled.
func (c *Config) ActiveBackends() []Backend {
	var out []Backend
	for _, b := range c.Backends {
		if !b.Disabled {
			out = append(out, b)
		}
	}
	return out
}

func (c *Config) clone() *Config {
	data, _ := json.Marshal(c)
	var out Config
	_ = json.Unmarshal(data, &out)
	return &out
}

func (c *Config) validate() error {
	if len(c.MasterKey) != crypto.KeySize {
		return errors.New("vault: bad master key")
	}
	if c.DataShards < 1 || c.ParityShards < 0 || c.DataShards+c.ParityShards > 256 {
		return fmt.Errorf("vault: bad erasure settings k=%d m=%d", c.DataShards, c.ParityShards)
	}
	seen := map[string]bool{}
	for _, b := range c.Backends {
		if b.ID == "" || seen[b.ID] {
			return fmt.Errorf("vault: missing or duplicate backend id %q", b.ID)
		}
		seen[b.ID] = true
	}
	return nil
}

// New returns a fresh config with a random vault id and master key.
func New(dataShards, parityShards int) (*Config, error) {
	k, err := crypto.NewKey()
	if err != nil {
		return nil, err
	}
	c := &Config{
		VaultID:      crypto.RandomID(16),
		Version:      1,
		MasterKey:    k[:],
		DataShards:   dataShards,
		ParityShards: parityShards,
	}
	return c, c.validate()
}

// sealer is a password-derived key together with the header it belongs to.
type sealer struct {
	header []byte
	key    crypto.Key
}

func newSealer(password []byte, p KDFParams) (*sealer, error) {
	salt := make([]byte, saltSize)
	if _, err := io.ReadFull(rand.Reader, salt); err != nil {
		return nil, err
	}
	h := make([]byte, 0, headerSize)
	h = append(h, magic...)
	h = binary.BigEndian.AppendUint32(h, p.Time)
	h = binary.BigEndian.AppendUint32(h, p.Memory)
	h = append(h, p.Threads)
	h = append(h, salt...)
	return &sealer{header: h, key: deriveKey(password, p, salt)}, nil
}

func deriveKey(password []byte, p KDFParams, salt []byte) crypto.Key {
	var k crypto.Key
	copy(k[:], argon2.IDKey(password, salt, p.Time, p.Memory, p.Threads, crypto.KeySize))
	return k
}

func parseHeader(data []byte) (KDFParams, []byte, error) {
	if len(data) < headerSize || !bytes.Equal(data[:8], magic) {
		return KDFParams{}, nil, ErrFormat
	}
	p := KDFParams{
		Time:    binary.BigEndian.Uint32(data[8:12]),
		Memory:  binary.BigEndian.Uint32(data[12:16]),
		Threads: data[16],
	}
	return p, data[17:headerSize], nil
}

func (s *sealer) seal(c *Config) ([]byte, error) {
	if err := c.validate(); err != nil {
		return nil, err
	}
	js, err := json.Marshal(c)
	if err != nil {
		return nil, err
	}
	ct, err := crypto.Seal(s.key, js, s.header)
	if err != nil {
		return nil, err
	}
	return append(append([]byte{}, s.header...), ct...), nil
}

func (s *sealer) open(data []byte) (*Config, error) {
	if _, _, err := parseHeader(data); err != nil {
		return nil, err
	}
	if !bytes.Equal(data[:headerSize], s.header) {
		return nil, ErrBadPassword
	}
	return openWithKey(s.key, data)
}

func openWithKey(k crypto.Key, data []byte) (*Config, error) {
	js, err := crypto.Open(k, data[headerSize:], data[:headerSize])
	if err != nil {
		return nil, ErrBadPassword
	}
	var c Config
	if err := json.Unmarshal(js, &c); err != nil {
		return nil, fmt.Errorf("vault: %w", err)
	}
	return &c, c.validate()
}

// Decode opens vault bytes with a password.
func Decode(data, password []byte) (*Config, error) {
	p, salt, err := parseHeader(data)
	if err != nil {
		return nil, err
	}
	return openWithKey(deriveKey(password, p, salt), data)
}

// Vault is an unlocked vault file. It is safe for concurrent use.
type Vault struct {
	mu     sync.Mutex
	path   string
	sealer *sealer
	cfg    *Config
	hooks  []func(*Config)
}

// Create writes a new vault file. It fails if the file exists.
func Create(path string, password []byte, c *Config, p KDFParams) (*Vault, error) {
	if _, err := os.Stat(path); err == nil {
		return nil, fmt.Errorf("vault: %s already exists", path)
	}
	s, err := newSealer(password, p)
	if err != nil {
		return nil, err
	}
	v := &Vault{path: path, sealer: s, cfg: c.clone()}
	return v, v.write()
}

// Open unlocks an existing vault file.
func Open(path string, password []byte) (*Vault, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	p, salt, err := parseHeader(data)
	if err != nil {
		return nil, err
	}
	s := &sealer{header: append([]byte{}, data[:headerSize]...), key: deriveKey(password, p, salt)}
	c, err := s.open(data)
	if err != nil {
		return nil, err
	}
	return &Vault{path: path, sealer: s, cfg: c}, nil
}

// Path returns the vault file path.
func (v *Vault) Path() string { return v.path }

// Config returns a copy of the current config.
func (v *Vault) Config() *Config {
	v.mu.Lock()
	defer v.mu.Unlock()
	return v.cfg.clone()
}

// OnChange registers fn to be called (with a copy) after every change.
func (v *Vault) OnChange(fn func(*Config)) {
	v.mu.Lock()
	v.hooks = append(v.hooks, fn)
	v.mu.Unlock()
}

// Update applies fn to a copy of the config, bumps the version and saves.
// If fn returns an error nothing changes.
func (v *Vault) Update(fn func(*Config) error) error {
	v.mu.Lock()
	next := v.cfg.clone()
	if err := fn(next); err != nil {
		v.mu.Unlock()
		return err
	}
	next.Version = v.cfg.Version + 1
	if err := next.validate(); err != nil {
		v.mu.Unlock()
		return err
	}
	prev := v.cfg
	v.cfg = next
	if err := v.write(); err != nil {
		v.cfg = prev
		v.mu.Unlock()
		return err
	}
	v.mu.Unlock()
	v.notify()
	return nil
}

// Encode returns the encrypted vault bytes (for the copy kept in storages).
func (v *Vault) Encode() ([]byte, error) {
	v.mu.Lock()
	defer v.mu.Unlock()
	return v.sealer.seal(v.cfg)
}

// Merge adopts a copy of the vault found elsewhere if it is newer.
// It returns true if the local config changed. A copy sealed with a
// different password returns ErrBadPassword: the user must unlock it.
//
// Devices are never lost: a newer copy gets the devices only known here.
// Two different copies with the same version (changed on two devices at
// once) are merged the same way on every device: the copy with the larger
// hash is the base, devices and storages of the other are added, and the
// version goes up so the result spreads.
func (v *Vault) Merge(data []byte) (bool, error) {
	v.mu.Lock()
	c, err := v.sealer.open(data)
	if err != nil {
		v.mu.Unlock()
		return false, err
	}
	if c.VaultID != v.cfg.VaultID {
		v.mu.Unlock()
		return false, errors.New("vault: copy belongs to another vault")
	}
	if c.Version < v.cfg.Version {
		v.mu.Unlock()
		return false, nil
	}
	var next *Config
	if c.Version > v.cfg.Version {
		next = c
		if addDevices(next, v.cfg) {
			next.Version++
		}
	} else {
		mine, _ := json.Marshal(v.cfg)
		theirs, _ := json.Marshal(c)
		if bytes.Equal(mine, theirs) {
			v.mu.Unlock()
			return false, nil
		}
		base, other := c, v.cfg.clone()
		hm, ht := sha256.Sum256(mine), sha256.Sum256(theirs)
		if bytes.Compare(hm[:], ht[:]) > 0 {
			base, other = v.cfg.clone(), c
		}
		addDevices(base, other)
		for _, b := range other.Backends {
			if _, ok := base.Backend(b.ID); !ok {
				base.Backends = append(base.Backends, b)
			}
		}
		base.Version++
		next = base
	}
	v.cfg = next
	if err := v.write(); err != nil {
		v.mu.Unlock()
		return false, err
	}
	v.mu.Unlock()
	v.notify()
	return true, nil
}

// addDevices adds devices of from missing in to.
func addDevices(to, from *Config) bool {
	added := false
	for _, d := range from.Devices {
		found := false
		for _, e := range to.Devices {
			if e.ID == d.ID {
				found = true
				break
			}
		}
		if !found {
			to.Devices = append(to.Devices, d)
			added = true
		}
	}
	return added
}

// VersionOf returns the config version inside vault bytes sealed with the
// same password as this vault.
func (v *Vault) VersionOf(data []byte) (uint64, error) {
	v.mu.Lock()
	defer v.mu.Unlock()
	c, err := v.sealer.open(data)
	if err != nil {
		return 0, err
	}
	if c.VaultID != v.cfg.VaultID {
		return 0, errors.New("vault: copy belongs to another vault")
	}
	return c.Version, nil
}

// ChangePassword re-encrypts the vault with a new password and fresh salt.
func (v *Vault) ChangePassword(password []byte, p KDFParams) error {
	s, err := newSealer(password, p)
	if err != nil {
		return err
	}
	v.mu.Lock()
	prevSealer, prevCfg := v.sealer, v.cfg
	next := v.cfg.clone()
	next.Version++
	v.sealer, v.cfg = s, next
	if err := v.write(); err != nil {
		v.sealer, v.cfg = prevSealer, prevCfg
		v.mu.Unlock()
		return err
	}
	v.mu.Unlock()
	v.notify()
	return nil
}

func (v *Vault) notify() {
	v.mu.Lock()
	c, hooks := v.cfg.clone(), append([]func(*Config){}, v.hooks...)
	v.mu.Unlock()
	for _, fn := range hooks {
		fn(c)
	}
}

// write saves atomically: temp file in the same directory, then rename.
func (v *Vault) write() error {
	data, err := v.sealer.seal(v.cfg)
	if err != nil {
		return err
	}
	dir := filepath.Dir(v.path)
	if err := os.MkdirAll(dir, 0o700); err != nil {
		return err
	}
	tmp, err := os.CreateTemp(dir, ".vault-*")
	if err != nil {
		return err
	}
	defer os.Remove(tmp.Name())
	if _, err := tmp.Write(data); err != nil {
		tmp.Close()
		return err
	}
	if err := tmp.Sync(); err != nil {
		tmp.Close()
		return err
	}
	if err := tmp.Close(); err != nil {
		return err
	}
	if err := os.Chmod(tmp.Name(), 0o600); err != nil {
		return err
	}
	return os.Rename(tmp.Name(), v.path)
}
