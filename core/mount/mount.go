//go:build !android

// Package mount shows the vault as a folder (FUSE on Linux, WinFsp on
// Windows) through cgofuse. Listing needs only the index; file content is
// downloaded when it is read. Opening a file for writing takes the vault
// write lock: if another device has the file open, the open fails with
// EACCES and editors fall back to read-only. Writes go to a local staging
// file. When the last handle is closed the file is queued on disk and
// uploaded in the background: close returns at once, the file stays
// readable from the staging copy, and a crash before the upload finished
// is recovered by RetryQueued.
package mount

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"io/fs"
	"log"
	"os"
	"path"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"github.com/winfsp/cgofuse/fuse"

	"cloudsync/core/crypto"
	"cloudsync/core/engine"
	"cloudsync/core/index"
	"cloudsync/core/lock"
)

// FS implements fuse.FileSystemInterface over an engine.
type FS struct {
	fuse.FileSystemBase
	e       *engine.Engine
	staging string // dir for files being written
	uid     uint32
	gid     uint32
	Log     *log.Logger

	mu      sync.Mutex
	next    uint64
	handles map[uint64]*handle
	writing map[string]*wfile // path → file open for writing
	// uploading holds files closed but not uploaded yet: they stay visible
	// and readable, and a new open for writing waits for the upload.
	uploading map[string]*wfile
	// inflight: queue records whose upload runs now (RetryQueued skips them).
	inflight map[string]bool
	started  time.Time
	// Linger is how long a write lock is kept after the file is closed, so
	// that saving again soon does not take the lock again (default 30 s).
	Linger time.Duration
}

type handle struct {
	path  string
	r     *engine.File // read-only handle
	w     *wfile       // write handle
	local *os.File     // read-only handle on the staging copy of an upload
	up    *wfile       // the upload local belongs to
}

// wfile is a file open for writing, shared by all write handles on it.
type wfile struct {
	path  string
	f     *os.File
	lock  *lock.Lock
	refs  int
	dirty bool
	mtime time.Time
	done  chan struct{} // closed when the upload finished

	// Set while uploading (guarded by FS.mu):
	queue      string // queue record on disk
	deleted    bool   // unlinked: do not record the upload
	committing bool   // being recorded at path: path cannot change any more
	uploaded   bool   // recorded in the vault
}

// New returns a file system for e. staging is a local dir for files being
// written and for uploads that failed and wait for a retry.
func New(e *engine.Engine, staging string) (*FS, error) {
	if err := os.MkdirAll(staging, 0o700); err != nil {
		return nil, err
	}
	return &FS{
		e: e, staging: staging,
		uid: uint32(os.Getuid()), gid: uint32(os.Getgid()),
		Log:       log.New(os.Stderr, "mount: ", log.LstdFlags),
		handles:   map[uint64]*handle{},
		writing:   map[string]*wfile{},
		uploading: map[string]*wfile{},
		inflight:  map[string]bool{},
		started:   time.Now(),
		Linger:    30 * time.Second,
	}, nil
}

// Mount mounts fs at dir and blocks until it is unmounted. Call Unmount on
// the returned host from another goroutine to stop.
func Mount(f *FS, dir string, opts ...string) (*fuse.FileSystemHost, <-chan bool) {
	host := fuse.NewFileSystemHost(f)
	host.SetCapReaddirPlus(true)
	done := make(chan bool, 1)
	go func() {
		defer func() {
			if r := recover(); r != nil { // cgofuse panics when libfuse is missing
				f.Log.Printf("mount: %v", r)
				done <- false
			}
		}()
		done <- host.Mount(dir, append([]string{"-o", "fsname=cloudsync,subtype=cloudsync"}, opts...))
	}()
	return host, done
}

func ctx() context.Context { return context.Background() }

func errno(err error) int {
	var le *lock.LockedError
	switch {
	case err == nil:
		return 0
	case errors.Is(err, fs.ErrNotExist):
		return -fuse.ENOENT
	case errors.Is(err, fs.ErrExist):
		return -fuse.EEXIST
	case errors.Is(err, engine.ErrIsDir):
		return -fuse.EISDIR
	case errors.Is(err, engine.ErrNotDir):
		return -fuse.ENOTDIR
	case errors.Is(err, engine.ErrNotEmpty):
		return -fuse.ENOTEMPTY
	case errors.As(err, &le):
		return -fuse.EACCES
	}
	return -fuse.EIO
}

func (f *FS) fill(st *fuse.Stat_t, en index.Entry) {
	*st = fuse.Stat_t{Uid: f.uid, Gid: f.gid, Nlink: 1}
	t := en.Time
	if t.IsZero() {
		t = f.started
	}
	if en.Dir {
		st.Mode = fuse.S_IFDIR | 0o755
		st.Nlink = 2
	} else {
		st.Mode = fuse.S_IFREG | 0o644
		st.Size = en.Version.Size
		t = en.Version.ModTime
		if m := en.Version.Mode & 0o777; m != 0 {
			st.Mode = fuse.S_IFREG | m
		}
	}
	ts := fuse.NewTimespec(t)
	st.Mtim, st.Ctim, st.Atim, st.Birthtim = ts, ts, ts, ts
	st.Blksize = 4096
	st.Blocks = (st.Size + 511) / 512
}

func (f *FS) Statfs(_ string, st *fuse.Statfs_t) int {
	*st = fuse.Statfs_t{Bsize: 4096, Frsize: 4096, Blocks: 1 << 40, Bfree: 1 << 39, Bavail: 1 << 39, Files: 1 << 30, Ffree: 1 << 29, Namemax: 255}
	return 0
}

// live returns the local file for p while it is written or uploading.
func (f *FS) live(p string) *wfile {
	f.mu.Lock()
	defer f.mu.Unlock()
	if w := f.writing[p]; w != nil {
		return w
	}
	return f.uploading[p]
}

func (f *FS) Getattr(p string, st *fuse.Stat_t, _ uint64) int {
	if w := f.live(p); w != nil {
		info, err := w.f.Stat()
		if err != nil { // the upload just finished: the index has it
			return f.getattrIndex(p, st)
		}
		*st = fuse.Stat_t{Mode: fuse.S_IFREG | 0o644, Nlink: 1, Uid: f.uid, Gid: f.gid, Size: info.Size(), Blksize: 4096}
		f.mu.Lock()
		ts := fuse.NewTimespec(w.mtime)
		f.mu.Unlock()
		st.Mtim, st.Ctim, st.Atim = ts, ts, ts
		return 0
	}
	return f.getattrIndex(p, st)
}

func (f *FS) getattrIndex(p string, st *fuse.Stat_t) int {
	en, err := f.e.Stat(p)
	if err != nil {
		return errno(err)
	}
	f.fill(st, en)
	return 0
}

func (f *FS) Opendir(p string) (int, uint64) {
	en, err := f.e.Stat(p)
	if err != nil {
		return errno(err), ^uint64(0)
	}
	if !en.Dir {
		return -fuse.ENOTDIR, ^uint64(0)
	}
	return 0, 0
}

func (f *FS) Readdir(p string, fill func(string, *fuse.Stat_t, int64) bool, _ int64, _ uint64) int {
	list, err := f.e.List(p)
	if err != nil {
		return errno(err)
	}
	fill(".", nil, 0)
	fill("..", nil, 0)
	seen := map[string]bool{}
	for _, en := range list {
		var st fuse.Stat_t
		f.fill(&st, en)
		seen[en.Name()] = true
		if !fill(en.Name(), &st, 0) {
			break
		}
	}
	// Files just created and not uploaded yet.
	f.mu.Lock()
	var extra []string
	for _, m := range []map[string]*wfile{f.writing, f.uploading} {
		for wp := range m {
			if dir, name := splitPath(wp); dir == index.Clean(p) && !seen[name] {
				seen[name] = true
				extra = append(extra, name)
			}
		}
	}
	f.mu.Unlock()
	for _, name := range extra {
		fill(name, nil, 0)
	}
	return 0
}

func splitPath(p string) (string, string) {
	i := strings.LastIndexByte(p, '/')
	if i <= 0 {
		return "/", p[i+1:]
	}
	return p[:i], p[i+1:]
}

func (f *FS) add(h *handle) uint64 {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.next++
	f.handles[f.next] = h
	return f.next
}

func (f *FS) get(fh uint64) *handle {
	f.mu.Lock()
	defer f.mu.Unlock()
	return f.handles[fh]
}

func (f *FS) Open(p string, flags int) (int, uint64) {
	if flags&fuse.O_ACCMODE == fuse.O_RDONLY {
		f.mu.Lock()
		w := f.writing[p]
		if w != nil {
			w.refs++
		}
		up := f.uploading[p]
		f.mu.Unlock()
		if w != nil { // read what this device is writing right now
			return 0, f.add(&handle{path: p, w: w})
		}
		if up != nil { // read the copy being uploaded
			if local, err := os.Open(up.f.Name()); err == nil {
				return 0, f.add(&handle{path: p, local: local, up: up})
			}
			<-up.done // it was just uploaded and removed
		}
		r, err := f.e.OpenFile(ctx(), p)
		if err != nil {
			return errno(err), ^uint64(0)
		}
		return 0, f.add(&handle{path: p, r: r})
	}
	w, err := f.openWrite(p, flags&fuse.O_TRUNC != 0, false)
	if err != nil {
		return errno(err), ^uint64(0)
	}
	return 0, f.add(&handle{path: p, w: w})
}

func (f *FS) Create(p string, flags int, _ uint32) (int, uint64) {
	w, err := f.openWrite(p, true, true)
	if err != nil {
		return errno(err), ^uint64(0)
	}
	return 0, f.add(&handle{path: p, w: w})
}

// openWrite takes the lock and prepares the staging file.
func (f *FS) openWrite(p string, trunc, create bool) (*wfile, error) {
	f.mu.Lock()
	if up := f.uploading[p]; up != nil {
		f.mu.Unlock()
		<-up.done
		f.mu.Lock()
	}
	if w := f.writing[p]; w != nil {
		w.refs++
		f.mu.Unlock()
		if trunc {
			w.f.Truncate(0)
			f.touch(w)
		}
		return w, nil
	}
	f.mu.Unlock()

	en, statErr := f.e.Stat(p)
	if statErr == nil && en.Dir {
		return nil, engine.ErrIsDir
	}
	if statErr != nil && !create {
		return nil, statErr
	}
	l, err := f.e.Lock(ctx(), p)
	switch {
	case errors.Is(err, lock.ErrNoQuorum):
		// Offline: edit anyway; a concurrent edit becomes a conflict copy.
		f.Log.Printf("%s: storages unreachable, writing without a lock", p)
	case err != nil:
		return nil, err
	}
	release := func() {
		if l != nil {
			l.Release(ctx())
		}
	}
	tmp, err := os.CreateTemp(f.staging, "w-*")
	if err != nil {
		release()
		return nil, err
	}
	w := &wfile{path: p, f: tmp, lock: l, refs: 1, dirty: create || trunc, mtime: time.Now(), done: make(chan struct{})}
	if statErr == nil && !trunc {
		r, err := f.e.OpenFile(ctx(), p)
		if err == nil {
			_, err = r.WriteTo(tmp)
		}
		if err != nil {
			tmp.Close()
			os.Remove(tmp.Name())
			release()
			return nil, err
		}
		w.mtime = en.Version.ModTime
	}
	f.mu.Lock()
	if other := f.writing[p]; other != nil { // raced with another open
		other.refs++
		f.mu.Unlock()
		tmp.Close()
		os.Remove(tmp.Name())
		release()
		return other, nil
	}
	f.writing[p] = w
	f.mu.Unlock()
	return w, nil
}

func (f *FS) Read(p string, buf []byte, off int64, fh uint64) int {
	h := f.get(fh)
	if h == nil {
		return -fuse.EBADF
	}
	var n int
	var err error
	switch {
	case h.w != nil:
		n, err = h.w.f.ReadAt(buf, off)
	case h.local != nil:
		n, err = h.local.ReadAt(buf, off)
	default:
		n, err = h.r.ReadAt(buf, off)
	}
	if err != nil && !errors.Is(err, io.EOF) {
		f.Log.Printf("read %s: %v", p, err)
		return -fuse.EIO
	}
	return n
}

func (f *FS) Write(p string, buf []byte, off int64, fh uint64) int {
	h := f.get(fh)
	if h == nil || h.w == nil {
		return -fuse.EBADF
	}
	n, err := h.w.f.WriteAt(buf, off)
	if err != nil {
		return -fuse.EIO
	}
	f.touch(h.w)
	return n
}

func (f *FS) Truncate(p string, size int64, fh uint64) int {
	if h := f.get(fh); h != nil && h.w != nil {
		if err := h.w.f.Truncate(size); err != nil {
			return -fuse.EIO
		}
		f.touch(h.w)
		return 0
	}
	// truncate(2) on a path: open for writing, truncate, close.
	w, err := f.openWrite(p, size == 0, false)
	if err != nil {
		return errno(err)
	}
	if err := w.f.Truncate(size); err != nil {
		return -fuse.EIO
	}
	f.touch(w)
	return f.closeWrite(w)
}

func (f *FS) touch(w *wfile) {
	f.mu.Lock()
	w.dirty, w.mtime = true, time.Now()
	f.mu.Unlock()
}

func (f *FS) Flush(string, uint64) int { return 0 }

func (f *FS) Fsync(string, bool, uint64) int { return 0 }

func (f *FS) Release(p string, fh uint64) int {
	f.mu.Lock()
	h := f.handles[fh]
	delete(f.handles, fh)
	f.mu.Unlock()
	if h != nil && h.local != nil {
		h.local.Close()
		f.mu.Lock()
		gone := h.up.uploaded || h.up.deleted
		f.mu.Unlock()
		if gone { // on Windows it could not be removed while open
			_ = os.Remove(h.local.Name())
		}
	}
	if h == nil || h.w == nil {
		return 0
	}
	return f.closeWrite(h.w)
}

// closeWrite drops a reference. The last one queues the file and starts
// its upload in the background; the lock is released after it.
func (f *FS) closeWrite(w *wfile) int {
	f.mu.Lock()
	w.refs--
	last := w.refs == 0
	if last && f.writing[w.path] == w {
		delete(f.writing, w.path)
		if !w.deleted {
			f.uploading[w.path] = w
		}
	}
	dirty, mtime, deleted := w.dirty, w.mtime, w.deleted
	f.mu.Unlock()
	if !last {
		return 0
	}
	if !dirty || deleted {
		f.endUpload(w, false)
		w.f.Close()
		os.Remove(w.f.Name())
		return 0
	}
	// On disk first: an edit survives a crash during the upload.
	f.mu.Lock()
	p := w.path
	f.mu.Unlock()
	q, err := f.queue(p, w.f.Name(), mtime)
	if err != nil {
		f.Log.Printf("cannot queue %s: %v; uploading now", p, err)
		f.upload(w, mtime)
		return 0
	}
	f.mu.Lock()
	w.queue = q
	f.inflight[q] = true
	f.mu.Unlock()
	go f.upload(w, mtime)
	return 0
}

// upload stores w's content, records it at w's current path (it may have
// been renamed meanwhile) and releases the lock.
func (f *FS) upload(w *wfile, mtime time.Time) {
	err := f.store(w, mtime)
	f.mu.Lock()
	q, p := w.queue, w.path
	delete(f.inflight, q)
	f.mu.Unlock()
	if err != nil {
		if q != "" { // RetryQueued uploads it later
			f.Log.Printf("upload %s failed, queued for retry: %v", p, err)
		} else {
			f.Log.Printf("upload %s failed: %v (content kept in %s)", p, err, w.f.Name())
		}
		f.endUpload(w, false)
		w.f.Close()
		return
	}
	if q != "" {
		os.Remove(q)
	}
	f.endUpload(w, true)
	w.f.Close()
	os.Remove(w.f.Name())
}

func (f *FS) store(w *wfile, mtime time.Time) error {
	f.mu.Lock()
	deleted := w.deleted
	f.mu.Unlock()
	if deleted {
		return nil
	}
	if _, err := w.f.Seek(0, io.SeekStart); err != nil {
		return err
	}
	v, err := f.e.StoreFile(ctx(), w.f, mtime)
	if err != nil {
		return err
	}
	f.mu.Lock()
	w.committing = true
	p, deleted := w.path, w.deleted
	f.mu.Unlock()
	if deleted {
		return nil
	}
	_, err = f.e.CommitFile(ctx(), p, v)
	return err
}

// endUpload takes w out of the uploading files, wakes up who waits for
// it and lets its lock go after the linger time.
func (f *FS) endUpload(w *wfile, ok bool) {
	f.mu.Lock()
	if f.uploading[w.path] == w {
		delete(f.uploading, w.path)
	}
	w.uploaded = ok
	f.mu.Unlock()
	close(w.done)
	if w.lock != nil {
		l := w.lock
		time.AfterFunc(f.Linger, func() { l.Release(ctx()) })
	}
}

// pending returns the file at p that is written or uploading and whose
// path can still change (nil if none).
func (f *FS) pending(p string) *wfile {
	if w := f.writing[p]; w != nil {
		return w
	}
	if w := f.uploading[p]; w != nil && !w.committing {
		return w
	}
	return nil
}

// replacePending drops the file written or uploading at p, which a rename
// is about to replace (saving twice in a row does not wait for the first
// upload). One that is being recorded already is waited for.
func (f *FS) replacePending(p string) {
	f.mu.Lock()
	if w := f.pending(p); w != nil {
		w.deleted = true
		for _, m := range []map[string]*wfile{f.writing, f.uploading} {
			if m[p] == w {
				delete(m, p)
			}
		}
		f.mu.Unlock()
		return
	}
	w := f.uploading[p]
	f.mu.Unlock()
	if w != nil {
		<-w.done
	}
}

// waitUnder waits for uploads of p and of files below p to finish.
func (f *FS) waitUnder(p string) {
	p = index.Clean(p)
	for {
		f.mu.Lock()
		var w *wfile
		for wp, u := range f.uploading {
			if wp == p || strings.HasPrefix(wp, p+"/") || p == "/" {
				w = u
				break
			}
		}
		f.mu.Unlock()
		if w == nil {
			return
		}
		<-w.done
	}
}

type queued struct {
	Path  string    `json:"path"`
	File  string    `json:"file"`
	MTime time.Time `json:"mtime"`
}

// queue writes a record of an upload to the staging dir and returns its name.
func (f *FS) queue(p, file string, mtime time.Time) (string, error) {
	name := filepath.Join(f.staging, "q-"+crypto.RandomID(8)+".json")
	return name, writeQueue(name, queued{p, file, mtime})
}

func writeQueue(name string, q queued) error {
	data, err := json.Marshal(q)
	if err != nil {
		return err
	}
	tmp := name + ".tmp"
	if err := os.WriteFile(tmp, data, 0o600); err != nil {
		return err
	}
	return os.Rename(tmp, name)
}

// RetryQueued uploads edits whose upload failed earlier. It returns how
// many are still waiting.
func (f *FS) RetryQueued() int {
	names, _ := filepath.Glob(filepath.Join(f.staging, "q-*.json"))
	left := 0
	for _, n := range names {
		f.mu.Lock()
		busy := f.inflight[n]
		f.mu.Unlock()
		if busy { // uploading in the background right now
			left++
			continue
		}
		data, err := os.ReadFile(n)
		if err != nil {
			continue
		}
		var q queued
		if json.Unmarshal(data, &q) != nil {
			continue
		}
		file, err := os.Open(q.File)
		if err != nil {
			os.Remove(n)
			continue
		}
		_, err = f.e.PutFile(ctx(), q.Path, file, q.MTime)
		file.Close()
		if err != nil {
			left++
			continue
		}
		os.Remove(q.File)
		os.Remove(n)
	}
	return left
}

func (f *FS) Mkdir(p string, _ uint32) int {
	if _, err := f.e.Stat(p); err == nil {
		return -fuse.EEXIST
	}
	return errno(f.e.Mkdir(ctx(), p))
}

func (f *FS) Rmdir(p string) int {
	f.mu.Lock()
	for _, m := range []map[string]*wfile{f.writing, f.uploading} {
		for wp := range m {
			if strings.HasPrefix(wp, index.Clean(p)+"/") {
				f.mu.Unlock()
				return -fuse.ENOTEMPTY
			}
		}
	}
	f.mu.Unlock()
	en, err := f.e.Stat(p)
	if err != nil {
		return errno(err)
	}
	if !en.Dir {
		return -fuse.ENOTDIR
	}
	return errno(f.e.Remove(ctx(), p, false))
}

func (f *FS) Unlink(p string) int {
	f.mu.Lock()
	w := f.pending(p)
	if w != nil { // written or uploading here: drop it
		w.deleted = true
		if f.writing[p] == w {
			delete(f.writing, p)
		}
		if f.uploading[p] == w {
			delete(f.uploading, p)
		}
	}
	f.mu.Unlock()
	if w != nil {
		if _, err := f.e.Stat(p); err != nil {
			return 0 // never reached the vault
		}
		return errno(f.e.Remove(ctx(), p, false))
	}
	f.waitUnder(p)
	en, err := f.e.Stat(p)
	if err != nil {
		return errno(err)
	}
	if en.Dir {
		return -fuse.EISDIR
	}
	if h, err := f.e.LockHolder(ctx(), p); err == nil && h != nil && h.Device != f.e.DeviceID() {
		return -fuse.EACCES
	}
	return errno(f.e.Remove(ctx(), p, false))
}

func (f *FS) Rename(from, to string) int {
	from, to = index.Clean(from), index.Clean(to)
	f.mu.Lock()
	w := f.pending(from)
	f.mu.Unlock()
	if w != nil {
		return f.renamePending(w, from, to)
	}
	f.replacePending(to)
	f.waitUnder(from) // a folder with uploads in it
	f.waitUnder(to)
	src, err := f.e.Stat(from)
	if err != nil {
		return errno(err)
	}
	// rename(2) replaces an existing file: editors save this way.
	if dst, err := f.e.Stat(to); err == nil {
		if dst.Dir {
			if !src.Dir {
				return -fuse.EISDIR
			}
			if list, _ := f.e.List(to); len(list) > 0 {
				return -fuse.ENOTEMPTY
			}
		}
		if h, err := f.e.LockHolder(ctx(), to); err == nil && h != nil && h.Device != f.e.DeviceID() {
			return -fuse.EACCES
		}
		if err := f.e.Remove(ctx(), to, false); err != nil {
			return errno(err)
		}
	}
	return errno(f.e.Rename(ctx(), from, to))
}

// renamePending moves a file that is written or uploading (editors save to
// a temporary file and rename it over the original): its content is
// recorded at the new path when the upload ends.
func (f *FS) renamePending(w *wfile, from, to string) int {
	if dir, err := f.e.Stat(path.Dir(to)); err != nil {
		return errno(err)
	} else if !dir.Dir {
		return -fuse.ENOTDIR
	}
	if dst, err := f.e.Stat(to); err == nil {
		if dst.Dir {
			return -fuse.EISDIR
		}
		if h, err := f.e.LockHolder(ctx(), to); err == nil && h != nil && h.Device != f.e.DeviceID() {
			return -fuse.EACCES
		}
	}
	f.replacePending(to)
	f.mu.Lock()
	if w.committing || w.deleted || f.pending(from) != w {
		f.mu.Unlock()
		return f.Rename(from, to) // it changed meanwhile: start over
	}
	for _, m := range []map[string]*wfile{f.writing, f.uploading} {
		if m[from] == w {
			delete(m, from)
			m[to] = w
		}
	}
	w.path = to
	q, mtime := w.queue, w.mtime
	f.mu.Unlock()
	if q != "" {
		if err := writeQueue(q, queued{to, w.f.Name(), mtime}); err != nil {
			f.Log.Printf("rename %s: queue record not updated: %v", from, err)
		}
	}
	// The old path's own content (if it had any) goes away with the move.
	if _, err := f.e.Stat(from); err == nil {
		if err := f.e.Remove(ctx(), from, false); err != nil {
			return errno(err)
		}
	}
	return 0
}

// Metadata changes are accepted and ignored: the vault keeps content,
// size, mtime and permission bits set at upload.
func (f *FS) Chmod(string, uint32) int         { return 0 }
func (f *FS) Chown(string, uint32, uint32) int { return 0 }
func (f *FS) Utimens(p string, t []fuse.Timespec) int {
	if w := f.live(p); w != nil && len(t) == 2 {
		f.mu.Lock()
		w.mtime = t[1].Time()
		f.mu.Unlock()
	}
	return 0
}
func (f *FS) Access(string, uint32) int { return 0 }
