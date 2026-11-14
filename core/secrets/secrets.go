// Package secrets is the password safe: passwords, SSH keys, web3 keys
// and two-factor (TOTP) logins with their recovery codes, sorted into
// groups.
//
// A record is stored as an index.OpSecret in the devices' journals, so it
// syncs like the file tree. Its two parts are sealed with their own keys
// derived from the vault master key:
//   - Meta (title, login, URL, public key, group) is opened to list records;
//   - Data (password, notes, private key, TOTP secret, recovery codes)
//     is opened only when one record is
//     shown. Plaintext is never written anywhere: journals, pending ops and
//     their local copies hold the sealed bytes only.
package secrets

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"cloudsync/core/crypto"
	"cloudsync/core/index"
)

// Kind of entry.
type Kind string

const (
	KindPassword Kind = "password"
	KindSSH      Kind = "ssh"
	KindWeb3     Kind = "web3"
	KindTOTP     Kind = "totp" // two-factor codes and recovery codes
)

// Meta is the part of an entry shown in lists.
type Meta struct {
	Kind     Kind   `json:"kind"`
	Title    string `json:"title"`
	Group    string `json:"group,omitempty"` // group id; unknown = no group
	Username string `json:"username,omitempty"`
	URL      string `json:"url,omitempty"`
	// Derived from the private key when it is saved (SSH, web3).
	KeyType     string  `json:"key_type,omitempty"` // ssh-ed25519, secp256k1, ...
	PublicKey   string  `json:"public_key,omitempty"`
	Fingerprint string  `json:"fingerprint,omitempty"` // SSH SHA256
	Address     string  `json:"address,omitempty"`     // web3
	Network     Network `json:"network,omitempty"`     // web3
	Comment     string  `json:"comment,omitempty"`     // SSH public key comment
	// How many recovery codes are left (TOTP), so a list can warn when
	// they run out without opening Data.
	RecoveryLeft int       `json:"recovery_left,omitempty"`
	Created      time.Time `json:"created"`
	Updated      time.Time `json:"updated"`
}

// Data is the secret part, opened only on demand.
type Data struct {
	Password   string `json:"password,omitempty"`
	Notes      string `json:"notes,omitempty"`
	PrivateKey string `json:"private_key,omitempty"`
	Passphrase string `json:"passphrase,omitempty"` // of an encrypted SSH key
	TOTP       *TOTP  `json:"totp,omitempty"`
	// Recovery codes not used yet; a used one is removed (UseRecoveryCode).
	RecoveryCodes []string `json:"recovery_codes,omitempty"`
}

// Entry is one record of the safe.
type Entry struct {
	ID         string
	Version    string // op id of this content: the parent of the next change
	Device     string // who made it
	ConflictOf string // set on a conflict copy
	Meta
	Data *Data // nil when not opened
}

// GroupMeta is the content of a group.
type GroupMeta struct {
	Name string `json:"name"`
	Icon []byte `json:"icon,omitempty"` // PNG / JPEG / WebP / GIF
}

// Group of entries.
type Group struct {
	ID, Version, ConflictOf string
	GroupMeta
}

// MaxIcon is the largest group picture; the app scales pictures down to
// fit. It is in every op that changes the group, forever, so it is small.
const MaxIcon = 64 << 10

// Limits on text, so a record stays a small part of a journal segment.
const (
	maxTitle = 512
	maxText  = 64 << 10
)

// Keys seals and opens records.
type Keys struct{ meta, data crypto.Key }

// NewKeys derives the safe keys from the vault master key.
func NewKeys(master crypto.Key) Keys {
	return Keys{meta: master.Derive("secret-meta", nil), data: master.Derive("secret-data", nil)}
}

func ad(part, id string) []byte { return []byte("secret/" + part + "/" + id) }

func (k Keys) seal(key crypto.Key, part, id string, v any) ([]byte, error) {
	plain, err := json.Marshal(v)
	if err != nil {
		return nil, err
	}
	defer wipe(plain)
	return crypto.Seal(key, plain, ad(part, id))
}

func (k Keys) open(key crypto.Key, part, id string, sealed []byte, v any) error {
	plain, err := crypto.Open(key, sealed, ad(part, id))
	if err != nil {
		return err
	}
	defer wipe(plain)
	return json.Unmarshal(plain, v)
}

// wipe overwrites a plaintext buffer once it is not needed. Go copies
// strings freely, so this only shortens how long the bytes stay around.
func wipe(b []byte) {
	for i := range b {
		b[i] = 0
	}
}

// SealEntry builds the change that stores e under id.
func (k Keys) SealEntry(id string, m Meta, d Data) (*index.SecretChange, error) {
	sm, err := k.seal(k.meta, "meta", id, m)
	if err != nil {
		return nil, err
	}
	sd, err := k.seal(k.data, "data", id, d)
	if err != nil {
		return nil, err
	}
	return &index.SecretChange{ID: id, Meta: sm, Data: sd}, nil
}

// SealGroup builds the change that stores a group under id.
func (k Keys) SealGroup(id string, g GroupMeta) (*index.SecretChange, error) {
	sm, err := k.seal(k.meta, "group", id, g)
	if err != nil {
		return nil, err
	}
	return &index.SecretChange{ID: id, Group: true, Meta: sm}, nil
}

// OpenEntry opens the meta of a record, and its data when withData.
func (k Keys) OpenEntry(s index.Secret, withData bool) (Entry, error) {
	e := Entry{ID: s.ID, Version: s.VersionID, Device: s.Device, ConflictOf: s.ConflictOf}
	if s.Group {
		return e, invalidf("%s is a group", s.ID)
	}
	if err := k.open(k.meta, "meta", s.SealedAs, s.Meta, &e.Meta); err != nil {
		return e, err
	}
	if withData {
		e.Data = &Data{}
		if err := k.open(k.data, "data", s.SealedAs, s.Data, e.Data); err != nil {
			return e, err
		}
	}
	return e, nil
}

// OpenGroup opens a group record.
func (k Keys) OpenGroup(s index.Secret) (Group, error) {
	g := Group{ID: s.ID, Version: s.VersionID, ConflictOf: s.ConflictOf}
	if !s.Group {
		return g, invalidf("%s is not a group", s.ID)
	}
	err := k.open(k.meta, "group", s.SealedAs, s.Meta, &g.GroupMeta)
	return g, err
}

// Prepare checks an entry before it is saved and fills what is derived
// from the private key. It does not change the private key itself.
// A TOTP entry's secret may be an otpauth:// URI: it is replaced by the
// base32 key, and the URI's issuer and account fill an empty title and
// login. Its recovery codes are parsed (ParseRecoveryCodes) from
// whatever was pasted. Prepare of a prepared entry changes nothing.
func Prepare(m *Meta, d *Data) error {
	if m.Kind != KindTOTP {
		d.TOTP, d.RecoveryCodes, m.RecoveryLeft = nil, nil, 0
	} else if err := prepareTOTP(m, d); err != nil {
		return err
	}
	m.Title = strings.TrimSpace(m.Title)
	if m.Title == "" {
		return invalid("a title is needed")
	}
	if len(m.Title) > maxTitle {
		return invalid("title is too long")
	}
	for _, s := range []string{m.Username, m.URL, m.Comment, d.Password, d.Notes, d.PrivateKey, d.Passphrase} {
		if len(s) > maxText {
			return invalid("a field is too long")
		}
	}
	m.KeyType, m.PublicKey, m.Fingerprint, m.Address = "", "", "", ""
	switch m.Kind {
	case KindPassword, KindTOTP:
		m.Network = ""
	case KindSSH:
		m.Network = ""
		pub, err := SSHPublic(d.PrivateKey, d.Passphrase, m.Comment)
		if err != nil {
			return err
		}
		m.KeyType, m.PublicKey, m.Fingerprint = pub.Type, pub.AuthorizedKey, pub.Fingerprint
	case KindWeb3:
		if m.Network == "" {
			m.Network = NetworkEVM
		}
		pub, err := Web3Public(m.Network, d.PrivateKey)
		if err != nil {
			return err
		}
		m.KeyType, m.PublicKey, m.Address = pub.Type, pub.PublicKey, pub.Address
	default:
		return invalidf("unknown kind %q", m.Kind)
	}
	return nil
}

func prepareTOTP(m *Meta, d *Data) error {
	if d.TOTP == nil {
		return invalid("the TOTP secret is empty")
	}
	t, info, err := ParseTOTP(d.TOTP.Secret, *d.TOTP)
	if err != nil {
		return err
	}
	d.TOTP = &t
	if strings.TrimSpace(m.Title) == "" {
		m.Title = info.Issuer
		if m.Title == "" {
			m.Title = info.Account
		}
	}
	if strings.TrimSpace(m.Username) == "" {
		m.Username = info.Account
	}
	d.Password, d.PrivateKey, d.Passphrase, m.Comment = "", "", "", ""
	d.RecoveryCodes = ParseRecoveryCodes(strings.Join(d.RecoveryCodes, "\n"))
	if len(d.RecoveryCodes) > maxRecoveryCodes {
		return invalidf("more than %d recovery codes", maxRecoveryCodes)
	}
	for _, c := range d.RecoveryCodes {
		if len(c) > maxRecoveryCode {
			return invalid("a recovery code is too long")
		}
	}
	m.RecoveryLeft = len(d.RecoveryCodes)
	return nil
}

// PrepareGroup checks a group before it is saved.
func PrepareGroup(g *GroupMeta) error {
	g.Name = strings.TrimSpace(g.Name)
	if g.Name == "" {
		return invalid("a group name is needed")
	}
	if len(g.Name) > maxTitle {
		return invalid("group name is too long")
	}
	if len(g.Icon) > MaxIcon {
		return invalidf("picture is larger than %d KiB", MaxIcon>>10)
	}
	if len(g.Icon) > 0 && !isImage(g.Icon) {
		return invalid("picture must be PNG, JPEG, WebP or GIF")
	}
	return nil
}

func isImage(b []byte) bool {
	switch {
	case bytes.HasPrefix(b, []byte("\x89PNG\r\n\x1a\n")),
		bytes.HasPrefix(b, []byte("\xff\xd8\xff")),
		bytes.HasPrefix(b, []byte("GIF87a")), bytes.HasPrefix(b, []byte("GIF89a")):
		return true
	case len(b) > 12 && string(b[:4]) == "RIFF" && string(b[8:12]) == "WEBP":
		return true
	}
	return false
}

// ErrInvalid marks errors about what the user entered (errors.Is).
var ErrInvalid = errors.New("invalid entry")

type invalidError struct{ err error }

func (e invalidError) Error() string        { return e.err.Error() }
func (e invalidError) Unwrap() error        { return e.err }
func (e invalidError) Is(target error) bool { return target == ErrInvalid }

func invalid(msg string) error { return invalidError{errors.New(msg)} }

func invalidf(format string, a ...any) error { return invalidError{fmt.Errorf(format, a...)} }
