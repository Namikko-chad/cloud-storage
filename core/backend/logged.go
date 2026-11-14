package backend

import (
	"context"
	"errors"
	"fmt"

	"cloudsync/core/eventlog"
)

// Logged wraps s so every failed call is written to log (missing objects
// are not failures). A nil log returns s unchanged.
func Logged(s Store, name string, log *eventlog.Log) Store {
	if log == nil {
		return s
	}
	return &loggedStore{Store: s, name: name, log: log}
}

type loggedStore struct {
	Store
	name string
	log  *eventlog.Log
}

func (l *loggedStore) fail(op, obj string, err error) {
	if err == nil || errors.Is(err, ErrNotFound) || errors.Is(err, context.Canceled) {
		return
	}
	// The object name is an HMAC: useless to a reader and makes every line
	// unique, so only the kind of object (its first path part) is kept.
	kind := obj
	for i := 0; i < len(obj); i++ {
		if obj[i] == '/' {
			kind = obj[:i]
			break
		}
	}
	l.log.Add(eventlog.Error, "storage", l.Store.ID(), fmt.Sprintf("%s: %s %s: %v", l.name, op, kind, err))
}

func (l *loggedStore) Put(ctx context.Context, name string, data []byte) error {
	err := l.Store.Put(ctx, name, data)
	l.fail("put", name, err)
	return err
}

func (l *loggedStore) PutNew(ctx context.Context, name string, data []byte) error {
	err := PutNew(ctx, l.Store, name, data)
	l.fail("put", name, err)
	return err
}

func (l *loggedStore) Stats() Stats { return StatsOf(l.Store) }

func (l *loggedStore) Get(ctx context.Context, name string) ([]byte, error) {
	b, err := l.Store.Get(ctx, name)
	l.fail("get", name, err)
	return b, err
}

func (l *loggedStore) Delete(ctx context.Context, name string) error {
	err := l.Store.Delete(ctx, name)
	l.fail("delete", name, err)
	return err
}

func (l *loggedStore) List(ctx context.Context, dir string) ([]string, error) {
	out, err := l.Store.List(ctx, dir)
	l.fail("list", dir, err)
	return out, err
}

func (l *loggedStore) ListDirs(ctx context.Context, dir string) ([]string, error) {
	out, err := l.Store.ListDirs(ctx, dir)
	l.fail("list", dir, err)
	return out, err
}

func (l *loggedStore) About(ctx context.Context) (Usage, error) {
	u, err := About(ctx, l.Store)
	if !errors.Is(err, ErrNoUsage) {
		l.fail("about", "", err)
	}
	return u, err
}

// Close closes the wrapped store if it can be closed.
func (l *loggedStore) Close() error {
	if c, ok := l.Store.(interface{ Close() error }); ok {
		return c.Close()
	}
	return nil
}
