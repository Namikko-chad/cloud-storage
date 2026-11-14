package engine

import (
	"bytes"
	"context"
	"errors"
	"io"
	"sync"

	"cloudsync/core/blob"
	"cloudsync/core/chunker"
	"cloudsync/core/index"
)

// uploadParallel is how many blobs upload at the same time. Each one
// writes a shard to k+m storages, so a slow storage delays its blob but
// not the ones after it. It also bounds memory: blobs wait in memory
// until stored.
const uploadParallel = 4

// uploader stores blobs, several at a time, skipping those stored already.
type uploader struct {
	e     *Engine
	ctx   context.Context
	stop  context.CancelFunc
	slots chan struct{}
	wg    sync.WaitGroup
	files map[string]*index.Version // content hash → version (small files)

	mu     sync.Mutex
	blobs  map[string]blob.Ref    // stored: blob id → ref
	flying map[string]*blobUpload // uploading, by blob id
	fixups []fixup
	err    error // first failed upload
}

// blobUpload is one blob being stored.
type blobUpload struct {
	done chan struct{}
	ref  blob.Ref
	err  error
}

// fixup sets the blob of a chunk once its upload finished.
type fixup struct {
	up *blobUpload
	c  *index.Chunk
}

func (e *Engine) newUploader(ctx context.Context) *uploader {
	kn := e.known()
	ctx, stop := context.WithCancel(ctx)
	return &uploader{
		e: e, ctx: ctx, stop: stop,
		slots:  make(chan struct{}, uploadParallel),
		files:  kn.files,
		blobs:  kn.blobs,
		flying: map[string]*blobUpload{},
	}
}

// put starts storing data (the uploader owns it from now on). It blocks
// while uploadParallel uploads run. cache keeps the plaintext locally.
func (u *uploader) put(data []byte, cache bool) *blobUpload {
	id := u.e.blobs.ID(data).String()
	u.mu.Lock()
	if ref, ok := u.blobs[id]; ok {
		u.mu.Unlock()
		up := &blobUpload{done: make(chan struct{}), ref: ref}
		close(up.done)
		return up
	}
	if up := u.flying[id]; up != nil {
		u.mu.Unlock()
		return up
	}
	up := &blobUpload{done: make(chan struct{})}
	u.flying[id] = up
	u.mu.Unlock()

	select {
	case u.slots <- struct{}{}:
	case <-u.ctx.Done():
		up.err = u.ctx.Err()
		close(up.done)
		return up
	}
	u.wg.Add(1)
	go func() {
		defer func() { <-u.slots; u.wg.Done() }()
		up.ref, up.err = u.e.blobs.Put(u.ctx, data)
		u.mu.Lock()
		delete(u.flying, id)
		if up.err == nil {
			u.blobs[id] = up.ref
		} else if u.err == nil {
			u.err = up.err
			u.stop() // no point in storing the rest
		}
		u.mu.Unlock()
		if up.err == nil && cache {
			u.e.cache.put(id, data, false)
		}
		close(up.done)
	}()
	return up
}

// later sets c.Blob when up finished (in finish).
func (u *uploader) later(up *blobUpload, c *index.Chunk) {
	u.fixups = append(u.fixups, fixup{up, c})
}

// failed returns the first upload error so far.
func (u *uploader) failed() error {
	u.mu.Lock()
	defer u.mu.Unlock()
	return u.err
}

// finish waits for every upload and fills in the chunks' blobs.
func (u *uploader) finish() error {
	u.wg.Wait()
	defer u.stop()
	if err := u.failed(); err != nil {
		return err
	}
	for _, f := range u.fixups {
		<-f.up.done
		if f.up.err != nil {
			return f.up.err
		}
		f.c.Blob = f.up.ref
	}
	return nil
}

// abort stops the uploads and waits for them to end.
func (u *uploader) abort() {
	u.stop()
	u.wg.Wait()
}

// storeContent uploads big content chunk by chunk (the chunks' blobs are
// filled in by finish). Small content (up to PackThreshold) is returned
// for packing instead.
func (u *uploader) storeContent(r io.Reader) (*index.Version, []byte, error) {
	e := u.e
	h := e.hashKey.NewMAC()
	head := make([]byte, e.opt.PackThreshold+1)
	n, err := io.ReadFull(r, head)
	if err != nil && !errors.Is(err, io.ErrUnexpectedEOF) && !errors.Is(err, io.EOF) {
		return nil, nil, err
	}
	head = head[:n]
	if n <= e.opt.PackThreshold {
		h.Write(head)
		return &index.Version{Size: int64(n), Hash: h.Sum(nil)}, head, nil
	}
	ch, err := chunker.New(io.TeeReader(io.MultiReader(bytes.NewReader(head), r), h), e.opt.Chunk, e.gear)
	if err != nil {
		return nil, nil, err
	}
	v := &index.Version{}
	var ups []*blobUpload
	for {
		data, err := ch.Next()
		if errors.Is(err, io.EOF) {
			break
		}
		if err != nil {
			return nil, nil, err
		}
		if err := u.failed(); err != nil {
			return nil, nil, err
		}
		// The chunker reuses its buffer; the upload keeps its own copy.
		ups = append(ups, u.put(bytes.Clone(data), true))
		v.Chunks = append(v.Chunks, index.Chunk{Length: len(data)})
		v.Size += int64(len(data))
	}
	for i, up := range ups {
		u.later(up, &v.Chunks[i])
	}
	v.Hash = h.Sum(nil)
	return v, nil, nil
}
