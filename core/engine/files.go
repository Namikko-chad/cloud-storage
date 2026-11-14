package engine

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"path"
	"strings"
	"sync"
	"time"

	"cloudsync/core/blob"
	"cloudsync/core/index"
)

// Errors returned for file operations.
var (
	ErrNotFound = fs.ErrNotExist
	ErrIsDir    = errors.New("is a directory")
	ErrNotDir   = errors.New("not a directory")
	ErrNotEmpty = errors.New("directory not empty")
)

// Upload is one file to store.
type Upload struct {
	Path    string
	Open    func() (io.ReadCloser, error)
	ModTime time.Time
	Mode    uint32
}

// UploadBytes is a convenience Upload for in-memory content.
func UploadBytes(p string, data []byte, mtime time.Time) Upload {
	return Upload{Path: p, ModTime: mtime, Open: func() (io.ReadCloser, error) {
		return io.NopCloser(bytes.NewReader(data)), nil
	}}
}

// known lists what is stored already, for deduplication.
type known struct {
	blobs map[string]blob.Ref       // blob id → ref
	files map[string]*index.Version // content hash → version
}

func (e *Engine) known() known {
	k := known{blobs: map[string]blob.Ref{}, files: map[string]*index.Version{}}
	e.idx.Walk(func(en index.Entry) {
		if en.Version == nil {
			return
		}
		k.files[en.Version.Hash.String()] = en.Version
		for _, c := range en.Version.Chunks {
			k.blobs[c.Blob.ID.String()] = c.Blob
		}
	})
	return k
}

// pack collects small files into one blob.
type pack struct {
	buf     bytes.Buffer
	members []*index.Version
	offsets []int
}

// PutFiles stores files and records them in one journal segment. Each file
// replaces the version this device currently sees at its path; if another
// device changed it meanwhile, the index keeps both (conflict copy).
// Several blobs upload at the same time; the files are recorded once all
// of them are stored.
func (e *Engine) PutFiles(ctx context.Context, ups []Upload) ([]index.Entry, error) {
	paths := make([]string, len(ups))
	for i, u := range ups {
		p, err := e.checkFilePath(u.Path)
		if err != nil {
			return nil, err
		}
		paths[i] = p
	}
	vs, err := e.storeFiles(ctx, ups)
	if err != nil {
		return nil, err
	}
	ops := make([]index.Op, len(ups))
	for i, v := range vs {
		ops[i] = index.Op{Kind: index.OpPut, Path: paths[i], Parent: e.head(paths[i]), Version: v}
	}
	if err := e.commit(ctx, ops); err != nil {
		return nil, err
	}
	out := make([]index.Entry, 0, len(ops))
	for _, o := range ops {
		if en, ok := e.idx.Get(o.Path); ok {
			out = append(out, en)
		}
	}
	return out, nil
}

// checkFilePath cleans p and checks that a file can be stored there.
func (e *Engine) checkFilePath(p string) (string, error) {
	p = index.Clean(p)
	if p == "/" {
		return "", ErrIsDir
	}
	if en, ok := e.idx.Get(p); ok && en.Dir {
		return "", fmt.Errorf("%s: %w", p, ErrIsDir)
	}
	if err := e.checkParents(p); err != nil {
		return "", err
	}
	return p, nil
}

// storeFiles uploads the content of ups and returns their versions.
func (e *Engine) storeFiles(ctx context.Context, ups []Upload) ([]*index.Version, error) {
	u := e.newUploader(ctx)
	vs := make([]*index.Version, len(ups))
	var pk pack
	flushPack := func() {
		if len(pk.members) == 0 {
			return
		}
		up := u.put(pk.buf.Bytes(), false)
		for i, v := range pk.members {
			v.Chunks = []index.Chunk{{Offset: pk.offsets[i], Length: int(v.Size)}}
			u.files[v.Hash.String()] = v
			u.later(up, &v.Chunks[0])
		}
		pk = pack{}
	}
	for i, up := range ups {
		rc, err := up.Open()
		if err != nil {
			u.abort()
			return nil, err
		}
		v, small, err := u.storeContent(rc)
		rc.Close()
		if err != nil {
			u.abort()
			return nil, fmt.Errorf("%s: %w", up.Path, err)
		}
		v.ModTime, v.Mode = up.ModTime.UTC(), up.Mode
		vs[i] = v
		if small != nil {
			if same, ok := u.files[v.Hash.String()]; ok && len(same.Chunks) > 0 {
				v.Chunks = same.Chunks // identical small file stored already
				continue
			}
			pk.members = append(pk.members, v)
			pk.offsets = append(pk.offsets, pk.buf.Len())
			pk.buf.Write(small)
			if pk.buf.Len() >= e.opt.PackSize {
				flushPack()
			}
		}
	}
	flushPack()
	if err := u.finish(); err != nil {
		return nil, err
	}
	return vs, nil
}

// PutFile stores one file.
func (e *Engine) PutFile(ctx context.Context, p string, r io.Reader, mtime time.Time) (index.Entry, error) {
	out, err := e.PutFiles(ctx, []Upload{{Path: p, ModTime: mtime, Open: func() (io.ReadCloser, error) {
		return io.NopCloser(r), nil
	}}})
	if err != nil {
		return index.Entry{}, err
	}
	if len(out) == 0 {
		return index.Entry{}, ErrNotFound
	}
	return out[0], nil
}

// StoreFile uploads content without recording it anywhere; CommitFile
// then puts it at a path. A file can be renamed between the two.
func (e *Engine) StoreFile(ctx context.Context, r io.Reader, mtime time.Time) (*index.Version, error) {
	vs, err := e.storeFiles(ctx, []Upload{{ModTime: mtime, Open: func() (io.ReadCloser, error) {
		return io.NopCloser(r), nil
	}}})
	if err != nil {
		return nil, err
	}
	return vs[0], nil
}

// CommitFile records v (from StoreFile) as the new content of p.
func (e *Engine) CommitFile(ctx context.Context, p string, v *index.Version) (index.Entry, error) {
	p, err := e.checkFilePath(p)
	if err != nil {
		return index.Entry{}, err
	}
	op := index.Op{Kind: index.OpPut, Path: p, Parent: e.head(p), Version: v}
	if err := e.commit(ctx, []index.Op{op}); err != nil {
		return index.Entry{}, err
	}
	return e.Stat(p)
}

func (e *Engine) head(p string) string {
	if en, ok := e.idx.Get(p); ok {
		return en.VersionID
	}
	return ""
}

func (e *Engine) checkParents(p string) error {
	for d := path.Dir(p); d != "/"; d = path.Dir(d) {
		if en, ok := e.idx.Get(d); ok && !en.Dir {
			return fmt.Errorf("%s: %w", d, ErrNotDir)
		}
	}
	return nil
}

// Stat returns the entry at p.
func (e *Engine) Stat(p string) (index.Entry, error) {
	en, ok := e.idx.Get(p)
	if !ok {
		return index.Entry{}, fmt.Errorf("%s: %w", p, ErrNotFound)
	}
	return en, nil
}

// List returns the children of dir.
func (e *Engine) List(dir string) ([]index.Entry, error) {
	en, err := e.Stat(dir)
	if err != nil {
		return nil, err
	}
	if !en.Dir {
		return nil, fmt.Errorf("%s: %w", dir, ErrNotDir)
	}
	return e.idx.List(dir), nil
}

// Mkdir creates dir and its parents.
func (e *Engine) Mkdir(ctx context.Context, dir string) error {
	dir = index.Clean(dir)
	if en, ok := e.idx.Get(dir); ok {
		if en.Dir {
			return nil
		}
		return fmt.Errorf("%s: %w", dir, ErrNotDir)
	}
	if err := e.checkParents(dir); err != nil {
		return err
	}
	return e.commit(ctx, []index.Op{{Kind: index.OpMkdir, Path: dir}})
}

// Remove deletes a file, or a directory (with its content if recursive).
func (e *Engine) Remove(ctx context.Context, p string, recursive bool) error {
	en, err := e.Stat(p)
	if err != nil {
		return err
	}
	if en.Path == "/" {
		return errors.New("cannot remove the root")
	}
	var ops []index.Op
	if en.Dir {
		var children []index.Entry
		prefix := en.Path + "/"
		e.idx.Walk(func(c index.Entry) {
			if strings.HasPrefix(c.Path, prefix) {
				children = append(children, c)
			}
		})
		if len(children) > 0 && !recursive {
			return fmt.Errorf("%s: %w", p, ErrNotEmpty)
		}
		// Deepest first, so every directory is empty when it is deleted.
		for i := len(children) - 1; i >= 0; i-- {
			ops = append(ops, index.Op{Kind: index.OpDelete, Path: children[i].Path, Parent: children[i].VersionID})
		}
	}
	ops = append(ops, index.Op{Kind: index.OpDelete, Path: en.Path, Parent: en.VersionID})
	return e.commit(ctx, ops)
}

// Rename moves a file or a directory tree. Content is not copied: the new
// entries point to the same blobs.
func (e *Engine) Rename(ctx context.Context, from, to string) error {
	src, err := e.Stat(from)
	if err != nil {
		return err
	}
	to = index.Clean(to)
	if src.Path == "/" || to == src.Path || strings.HasPrefix(to, src.Path+"/") {
		return errors.New("bad rename")
	}
	if dst, ok := e.idx.Get(to); ok && (dst.Dir || src.Dir) {
		return fmt.Errorf("%s: %w", to, fs.ErrExist)
	}
	if err := e.checkParents(to); err != nil {
		return err
	}
	var moved []index.Entry
	prefix := src.Path + "/"
	e.idx.Walk(func(c index.Entry) {
		if c.Path == src.Path || strings.HasPrefix(c.Path, prefix) {
			moved = append(moved, c)
		}
	})
	var ops []index.Op
	for _, c := range moved { // parents first
		np := to + strings.TrimPrefix(c.Path, src.Path)
		if c.Dir {
			ops = append(ops, index.Op{Kind: index.OpMkdir, Path: np})
		} else {
			ops = append(ops, index.Op{Kind: index.OpPut, Path: np, Parent: e.head(np), Version: c.Version})
		}
	}
	for i := len(moved) - 1; i >= 0; i-- { // children first
		ops = append(ops, index.Op{Kind: index.OpDelete, Path: moved[i].Path, Parent: moved[i].VersionID})
	}
	return e.commit(ctx, ops)
}

// File is an open file version. Reads fetch only the chunks they touch,
// and the next ones in the background while the file is read in order.
type File struct {
	e     *Engine
	Entry index.Entry
	ctx   context.Context
	offs  []int64 // start offset of each chunk

	mu   sync.Mutex
	last int // chunk read last (-1: none)
}

// OpenFile opens the current version of p for reading.
func (e *Engine) OpenFile(ctx context.Context, p string) (*File, error) {
	en, err := e.Stat(p)
	if err != nil {
		return nil, err
	}
	if en.Dir {
		return nil, fmt.Errorf("%s: %w", p, ErrIsDir)
	}
	f := &File{e: e, Entry: en, ctx: ctx, last: -1}
	var off int64
	for _, c := range en.Version.Chunks {
		f.offs = append(f.offs, off)
		off += int64(c.Length)
	}
	return f, nil
}

// Size is the file size.
func (f *File) Size() int64 { return f.Entry.Version.Size }

// ReadAt implements io.ReaderAt.
func (f *File) ReadAt(p []byte, off int64) (int, error) {
	if off < 0 {
		return 0, errors.New("negative offset")
	}
	n := 0
	for i, c := range f.Entry.Version.Chunks {
		if len(p) == 0 {
			break
		}
		start, end := f.offs[i], f.offs[i]+int64(c.Length)
		if off >= end {
			continue
		}
		f.readAhead(i)
		data, err := f.e.blobData(f.ctx, c.Blob)
		if err != nil {
			return n, err
		}
		if c.Offset+c.Length > len(data) {
			return n, fmt.Errorf("chunk out of range in blob %s", c.Blob.ID)
		}
		piece := data[c.Offset : c.Offset+c.Length][off-start:]
		k := copy(p, piece)
		p, off, n = p[k:], off+int64(k), n+k
	}
	if len(p) > 0 {
		return n, io.EOF
	}
	return n, nil
}

// WriteTo copies the whole file to w.
func (f *File) WriteTo(w io.Writer) (int64, error) {
	return io.Copy(w, io.NewSectionReader(f, 0, f.Size()))
}

// readAhead starts downloading the chunks after chunk i when the file is
// read in order (a reader is at the start or right after the last chunk).
func (f *File) readAhead(i int) {
	f.mu.Lock()
	seq := i == 0 || i == f.last || i == f.last+1
	f.last = i
	f.mu.Unlock()
	if !seq {
		return
	}
	chunks := f.Entry.Version.Chunks
	for j := i + 1; j < len(chunks) && j <= i+readAhead; j++ {
		f.e.prefetch(chunks[j].Blob)
	}
}

// readAhead is how many chunks past the one being read are downloaded.
const readAhead = 2

// readAheadParallel bounds read-ahead downloads of the whole engine.
const readAheadParallel = 4

// fetchCall is one blob download that several readers can wait for.
type fetchCall struct {
	done chan struct{}
	data []byte
	err  error
}

// prefetch downloads a blob into the cache in the background, unless it
// is there, already downloading, or too many read-aheads run.
func (e *Engine) prefetch(ref blob.Ref) {
	id := ref.ID.String()
	if e.cache.has(id) {
		return
	}
	e.fetchMu.Lock()
	_, busy := e.fetching[id]
	e.fetchMu.Unlock()
	if busy {
		return
	}
	select {
	case e.ahead <- struct{}{}:
	default:
		return
	}
	go func() {
		defer func() { <-e.ahead }()
		_, _ = e.blobData(context.Background(), ref)
	}()
}

// blobData returns the plaintext of a blob, from the cache when possible.
// Readers of a blob that is downloading wait for that download.
func (e *Engine) blobData(ctx context.Context, ref blob.Ref) ([]byte, error) {
	id := ref.ID.String()
	if d := e.cache.get(id); d != nil {
		return d, nil
	}
	e.fetchMu.Lock()
	c := e.fetching[id]
	if c == nil {
		c = &fetchCall{done: make(chan struct{})}
		e.fetching[id] = c
		// The download serves every waiter: one leaving does not stop it.
		go func() {
			c.data, c.err = e.blobs.Get(context.WithoutCancel(ctx), e.idx.Resolve(ref))
			if c.err == nil {
				e.cache.put(id, c.data, false)
			}
			e.fetchMu.Lock()
			delete(e.fetching, id)
			e.fetchMu.Unlock()
			close(c.done)
		}()
	}
	e.fetchMu.Unlock()
	select {
	case <-c.done:
		return c.data, c.err
	case <-ctx.Done():
		return nil, ctx.Err()
	}
}
