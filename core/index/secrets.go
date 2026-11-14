package index

import (
	"sort"
	"time"
)

// OpSecret creates, replaces or deletes one record of the password safe
// (an entry or a group). Its fields are sealed by package secrets; the
// index only folds them, it never sees plaintext.
const OpSecret Kind = "secret"

// SecretChange is the payload of an OpSecret.
type SecretChange struct {
	ID      string `json:"id"`
	Group   bool   `json:"group,omitempty"`
	Deleted bool   `json:"deleted,omitempty"`
	Meta    []byte `json:"meta,omitempty"` // sealed: shown in lists
	Data    []byte `json:"data,omitempty"` // sealed: opened only on demand
}

// Secret is the current state of one safe record.
type Secret struct {
	ID string
	// SealedAs is the id the payload was sealed for: the record's own id,
	// or for a conflict copy the id it collided with.
	SealedAs   string
	Group      bool
	Meta, Data []byte
	VersionID  string // op id of the current content
	Device     string
	Time       time.Time
	ConflictOf string // set on a conflict copy
}

// applySecret folds an OpSecret with the same rules as files: a change
// based on an old version is kept as a conflict copy, a delete of a record
// changed meanwhile is dropped.
func (x *Index) applySecret(o Op) {
	c := o.Secret
	if c == nil || c.ID == "" {
		return
	}
	cur := x.secrets[c.ID]
	head := ""
	if cur != nil {
		head = cur.VersionID
	}
	if c.Deleted {
		if cur != nil && head == o.Parent {
			delete(x.secrets, c.ID)
		}
		return
	}
	s := &Secret{
		ID: c.ID, SealedAs: c.ID, Group: c.Group, Meta: c.Meta, Data: c.Data,
		VersionID: o.ID(), Device: o.Device, Time: o.Time,
	}
	if cur != nil && head != o.Parent {
		s.ID = c.ID + "~" + o.ID()
		s.ConflictOf = c.ID
	}
	x.secrets[s.ID] = s
}

// Secrets returns all safe records, sorted by id.
func (x *Index) Secrets() []Secret {
	x.mu.RLock()
	defer x.mu.RUnlock()
	out := make([]Secret, 0, len(x.secrets))
	for _, s := range x.secrets {
		out = append(out, *s)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].ID < out[j].ID })
	return out
}

// Secret returns one safe record.
func (x *Index) Secret(id string) (Secret, bool) {
	x.mu.RLock()
	defer x.mu.RUnlock()
	s, ok := x.secrets[id]
	if !ok {
		return Secret{}, false
	}
	return *s, true
}
