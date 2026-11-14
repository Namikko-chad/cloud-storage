package backend

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"io"
	"os"
	"path"
	"path/filepath"
	"slices"
	"sort"
	"strings"
	"time"

	"github.com/rclone/rclone/fs"
	"github.com/rclone/rclone/fs/config/configmap"
	"github.com/rclone/rclone/fs/config/obscure"
	"github.com/rclone/rclone/fs/object"

	"cloudsync/core/vault"
)

// ParamSetter receives option changes rclone makes at runtime (refreshed
// OAuth tokens) so they can be written back to the vault.
type ParamSetter func(backendID, key, value string)

// RcloneStore is a Store backed by any rclone backend.
type RcloneStore struct {
	id string
	f  fs.Fs
}

// OpenRclone opens backend b. Objects live in <b.Root>/<vaultID>/.
// The options come only from b.Params and rclone's defaults: no rclone
// config file or environment is read, so two backends of one type never
// share anything.
func OpenRclone(ctx context.Context, vaultID string, b vault.Backend, onSet ParamSetter) (*RcloneStore, error) {
	info, err := fs.Find(b.Type)
	if err != nil {
		return nil, fmt.Errorf("backend %s: %w", b.Name, err)
	}
	params := configmap.Simple{}
	for k, v := range b.Params {
		params[k] = v
	}
	m := configmap.New()
	m.AddGetter(params, configmap.PriorityConfig)
	m.AddGetter(defaults(info.Options), configmap.PriorityDefault)
	m.AddSetter(setter(func(k, v string) {
		params[k] = v
		if onSet != nil {
			onSet(b.ID, k, v)
		}
	}))
	root := path.Join(b.Root, vaultID)
	// The Fs keeps the context it was made with for its whole life (OAuth
	// backends refresh tokens with it), so it must outlive the call that
	// opened it, e.g. an unlock request. Otherwise Drive fails with
	// "couldn't fetch token: context canceled" once the first token
	// expires. The caller's ctx still bounds how long we wait here.
	type result struct {
		f   fs.Fs
		err error
	}
	done := make(chan result, 1)
	go func() {
		f, err := info.NewFs(context.WithoutCancel(ctx), "cs-"+b.ID, root, m)
		done <- result{f, err}
	}()
	var f fs.Fs
	select {
	case r := <-done:
		f, err = r.f, r.err
	case <-ctx.Done():
		return nil, fmt.Errorf("backend %s: %w", b.Name, ctx.Err())
	}
	if err != nil && !errors.Is(err, fs.ErrorIsFile) {
		return nil, fmt.Errorf("backend %s: %w", b.Name, err)
	}
	return &RcloneStore{id: b.ID, f: f}, nil
}

// ObscureParams returns params with every password option of backend type
// obscured, as rclone stores them. Values already obscured stay as they are.
func ObscureParams(typ string, params map[string]string) (map[string]string, error) {
	info, err := fs.Find(typ)
	if err != nil {
		return nil, err
	}
	out := map[string]string{}
	for k, v := range params {
		opt := info.Options.Get(k)
		if opt == nil {
			// A typo or a guess (e.g. path=...) must not be dropped silently.
			return nil, fmt.Errorf("%s has no option %q (the folder goes into the storage's root, not into options)", typ, k)
		}
		out[k] = v
		if opt.IsPassword && v != "" {
			if _, err := obscure.Reveal(v); err == nil {
				continue
			}
			if out[k], err = obscure.Obscure(v); err != nil {
				return nil, err
			}
		}
	}
	return out, nil
}

// CheckRoot validates the folder a storage keeps its data in. For local
// disks it must be absolute: a relative one would depend on the working
// directory of whatever process opens the vault.
func CheckRoot(typ, root string) error {
	if typ == "local" && !filepath.IsAbs(root) {
		return fmt.Errorf("a local storage needs an absolute folder, got %q", root)
	}
	return nil
}

// Types lists the rclone backend types compiled in.
func Types() []string {
	var out []string
	for _, r := range fs.Registry {
		out = append(out, r.Name)
	}
	sort.Strings(out)
	return out
}

type defaults fs.Options

func (d defaults) Get(key string) (string, bool) {
	if opt := fs.Options(d).Get(key); opt != nil {
		return opt.String(), true
	}
	return "", false
}

type setter func(k, v string)

func (s setter) Set(k, v string) { s(k, v) }

func (r *RcloneStore) ID() string { return r.id }

// About asks the provider for the account's quota (the disk for local).
func (r *RcloneStore) About(ctx context.Context) (Usage, error) {
	do := r.f.Features().About
	if do == nil {
		return Usage{}, ErrNoUsage
	}
	u, err := do(ctx)
	if err != nil && (errors.Is(err, fs.ErrorDirNotFound) || errors.Is(err, os.ErrNotExist)) {
		// Nothing written yet (local disks look the folder up): the vault
		// folder is made on the first write anyway.
		if r.f.Mkdir(ctx, "") == nil {
			u, err = do(ctx)
		}
	}
	if err != nil {
		if errors.Is(err, fs.ErrorNotImplemented) {
			return Usage{}, ErrNoUsage
		}
		return Usage{}, err
	}
	get := func(p *int64) int64 {
		if p == nil {
			return -1
		}
		return *p
	}
	out := Usage{Total: get(u.Total), Used: get(u.Used), Free: get(u.Free)}
	if out.Free < 0 && out.Total >= 0 && out.Used >= 0 {
		out.Free = max(out.Total-out.Used, 0)
	}
	if out.Free < 0 {
		// Unlimited or unknown: nothing to plan with.
		return Usage{}, ErrNoUsage
	}
	return out, nil
}

func (r *RcloneStore) Put(ctx context.Context, name string, data []byte) error {
	// rclone's Put replaces an existing object; backends that allow two
	// objects with one name (Drive, Mega) look the name up themselves.
	info := object.NewStaticObjectInfo(name, time.Now(), int64(len(data)), true, nil, r.f)
	_, err := r.f.Put(ctx, bytes.NewReader(data), info)
	return err
}

// PutNew writes an object whose name was never used. On backends that
// look a name up before writing (Drive, Mega) that lookup is skipped.
func (r *RcloneStore) PutNew(ctx context.Context, name string, data []byte) error {
	put := r.f.Features().PutUnchecked
	if put == nil {
		return r.Put(ctx, name, data)
	}
	info := object.NewStaticObjectInfo(name, time.Now(), int64(len(data)), true, nil, r.f)
	_, err := put(ctx, bytes.NewReader(data), info)
	return err
}

func (r *RcloneStore) Get(ctx context.Context, name string) ([]byte, error) {
	o, err := r.f.NewObject(ctx, name)
	if errors.Is(err, fs.ErrorObjectNotFound) || errors.Is(err, fs.ErrorDirNotFound) || errors.Is(err, fs.ErrorIsDir) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	rc, err := o.Open(ctx)
	if err != nil {
		return nil, err
	}
	defer rc.Close()
	return io.ReadAll(rc)
}

func (r *RcloneStore) Delete(ctx context.Context, name string) error {
	o, err := r.f.NewObject(ctx, name)
	if errors.Is(err, fs.ErrorObjectNotFound) || errors.Is(err, fs.ErrorDirNotFound) {
		return nil
	}
	if err != nil {
		return err
	}
	return o.Remove(ctx)
}

func (r *RcloneStore) List(ctx context.Context, dir string) ([]string, error) {
	return r.list(ctx, dir, false)
}

func (r *RcloneStore) ListDirs(ctx context.Context, dir string) ([]string, error) {
	return r.list(ctx, dir, true)
}

func (r *RcloneStore) list(ctx context.Context, dir string, dirs bool) ([]string, error) {
	entries, err := r.f.List(ctx, strings.TrimSuffix(dir, "/"))
	if errors.Is(err, fs.ErrorDirNotFound) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	var out []string
	for _, e := range entries {
		_, isDir := e.(fs.Directory)
		if isDir == dirs {
			out = append(out, e.Remote())
		}
	}
	// Drive and Mega allow two entries with one name (e.g. a folder made
	// twice by concurrent writes); callers expect each name once.
	sort.Strings(out)
	return slices.Compact(out), nil
}
