package engine

import (
	"context"
	"fmt"
	"sort"
	"strings"
	"time"

	"cloudsync/core/crypto"
	"cloudsync/core/index"
	"cloudsync/core/secrets"
)

func (e *Engine) secretKeys() secrets.Keys { return secrets.NewKeys(e.cfg.Key()) }

// SafeList is the password safe without secret fields.
type SafeList struct {
	Groups  []secrets.Group
	Entries []secrets.Entry // Data is nil
	// Unreadable records (sealed with another key); should not happen.
	Broken int
}

// Safe lists the safe's groups and entries. Only the meta part of each
// entry is opened; passwords, notes and private keys stay sealed.
func (e *Engine) Safe() SafeList {
	k := e.secretKeys()
	var out SafeList
	for _, s := range e.idx.Secrets() {
		if s.Group {
			g, err := k.OpenGroup(s)
			if err != nil {
				out.Broken++
				continue
			}
			out.Groups = append(out.Groups, g)
			continue
		}
		en, err := k.OpenEntry(s, false)
		if err != nil {
			out.Broken++
			continue
		}
		out.Entries = append(out.Entries, en)
	}
	sort.SliceStable(out.Groups, func(i, j int) bool {
		return strings.ToLower(out.Groups[i].Name) < strings.ToLower(out.Groups[j].Name)
	})
	sort.SliceStable(out.Entries, func(i, j int) bool {
		return strings.ToLower(out.Entries[i].Title) < strings.ToLower(out.Entries[j].Title)
	})
	return out
}

// OpenSecret returns one entry with its secret fields.
func (e *Engine) OpenSecret(id string) (secrets.Entry, error) {
	s, ok := e.idx.Secret(id)
	if !ok || s.Group {
		return secrets.Entry{}, fmt.Errorf("%s: %w", id, ErrNotFound)
	}
	return e.secretKeys().OpenEntry(s, true)
}

// PutSecret creates (empty id) or replaces an entry. parent is the
// version the caller edited ("" = the current one); if another device
// changed the entry meanwhile, both versions are kept.
func (e *Engine) PutSecret(ctx context.Context, id, parent string, m secrets.Meta, d secrets.Data) (secrets.Entry, error) {
	if err := secrets.Prepare(&m, &d); err != nil {
		return secrets.Entry{}, err
	}
	now := time.Now().UTC()
	m.Updated = now
	if id == "" {
		id, parent = crypto.RandomID(12), ""
		m.Created = now
	} else {
		cur, ok := e.idx.Secret(id)
		if !ok && parent == "" {
			return secrets.Entry{}, fmt.Errorf("%s: %w", id, ErrNotFound)
		}
		if ok && cur.Group {
			return secrets.Entry{}, fmt.Errorf("secrets: %s is a group", id)
		}
		if ok {
			if old, err := e.secretKeys().OpenEntry(cur, false); err == nil && !old.Created.IsZero() {
				m.Created = old.Created
			}
			if parent == "" {
				parent = cur.VersionID
			}
		}
		if m.Created.IsZero() {
			m.Created = now
		}
	}
	ch, err := e.secretKeys().SealEntry(id, m, d)
	if err != nil {
		return secrets.Entry{}, err
	}
	op := index.Op{Kind: index.OpSecret, Path: "/", Parent: parent, Secret: ch}
	if err := e.commitSecret(ctx, &op); err != nil {
		return secrets.Entry{}, err
	}
	return secrets.Entry{ID: id, Version: op.ID(), Device: op.Device, Meta: m}, nil
}

// PutSecretGroup creates (empty id) or replaces a group.
func (e *Engine) PutSecretGroup(ctx context.Context, id string, g secrets.GroupMeta) (secrets.Group, error) {
	if err := secrets.PrepareGroup(&g); err != nil {
		return secrets.Group{}, err
	}
	parent := ""
	if id == "" {
		id = crypto.RandomID(12)
	} else {
		cur, ok := e.idx.Secret(id)
		if !ok || !cur.Group {
			return secrets.Group{}, fmt.Errorf("%s: %w", id, ErrNotFound)
		}
		parent = cur.VersionID
	}
	ch, err := e.secretKeys().SealGroup(id, g)
	if err != nil {
		return secrets.Group{}, err
	}
	op := index.Op{Kind: index.OpSecret, Path: "/", Parent: parent, Secret: ch}
	if err := e.commitSecret(ctx, &op); err != nil {
		return secrets.Group{}, err
	}
	return secrets.Group{ID: id, Version: op.ID(), GroupMeta: g}, nil
}

// DeleteSecret removes an entry or a group. Entries of a removed group
// are shown without a group.
func (e *Engine) DeleteSecret(ctx context.Context, id string) error {
	cur, ok := e.idx.Secret(id)
	if !ok {
		return fmt.Errorf("%s: %w", id, ErrNotFound)
	}
	// A conflict copy lives under its own id; deleting it needs that id in
	// the op, so the payload records the copy's id.
	op := index.Op{Kind: index.OpSecret, Path: "/", Parent: cur.VersionID,
		Secret: &index.SecretChange{ID: cur.ID, Group: cur.Group, Deleted: true}}
	return e.commitSecret(ctx, &op)
}

func (e *Engine) commitSecret(ctx context.Context, op *index.Op) error {
	ops := []index.Op{*op}
	if err := e.commit(ctx, ops); err != nil {
		return err
	}
	*op = ops[0]
	return nil
}

// TOTPCode is the current two-factor code of one entry.
type TOTPCode struct {
	ID      string
	Code    string
	Next    string // the code of the next period, for a login typed at the edge
	Period  int
	Expires time.Time
}

// TOTPCodes computes the current codes of every TOTP entry. Only the
// codes leave the engine, never the secrets.
func (e *Engine) TOTPCodes(now time.Time) []TOTPCode {
	k := e.secretKeys()
	var out []TOTPCode
	for _, s := range e.idx.Secrets() {
		if s.Group {
			continue
		}
		en, err := k.OpenEntry(s, false)
		if err != nil || en.Kind != secrets.KindTOTP {
			continue
		}
		if en, err = k.OpenEntry(s, true); err != nil || en.Data.TOTP == nil {
			continue
		}
		t := *en.Data.TOTP
		code, exp := t.Code(now)
		next, _ := t.Code(exp)
		out = append(out, TOTPCode{ID: en.ID, Code: code, Next: next, Period: t.Period, Expires: exp})
	}
	return out
}

// UseRecoveryCode removes a used recovery code from a TOTP entry.
func (e *Engine) UseRecoveryCode(ctx context.Context, id, code string) (secrets.Entry, error) {
	en, err := e.OpenSecret(id)
	if err != nil {
		return secrets.Entry{}, err
	}
	if en.Kind != secrets.KindTOTP {
		return secrets.Entry{}, fmt.Errorf("secrets: %s has no recovery codes: %w", id, secrets.ErrInvalid)
	}
	left := en.Data.RecoveryCodes[:0:0]
	found := false
	for _, c := range en.Data.RecoveryCodes {
		if !found && secrets.SameCode(c, code) {
			found = true
			continue
		}
		left = append(left, c)
	}
	if !found {
		return secrets.Entry{}, fmt.Errorf("recovery code: %w", ErrNotFound)
	}
	en.Data.RecoveryCodes = left
	return e.PutSecret(ctx, id, en.Version, en.Meta, *en.Data)
}
