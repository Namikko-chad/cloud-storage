package engine

import (
	"container/list"
	"os"
	"path/filepath"
	"sort"
	"sync"
	"time"
)

// cache keeps decrypted blobs on this device: files under dir, plus recent
// blobs in memory (up to memLimit bytes) so that small reads of a file and
// its read-ahead do not hit the disk.
// Blobs of pinned files are never evicted; the rest are dropped oldest
// first once they exceed limit bytes.
type cache struct {
	dir   string
	limit int64

	mu     sync.Mutex
	size   int64 // bytes on disk
	mem    *list.List
	memIdx map[string]*list.Element
	memLen int64                  // bytes in mem
	keep   func() map[string]bool // ids that must stay (pinned)
}

type memItem struct {
	id   string
	data []byte
}

// memLimit bounds the blobs kept in memory (a blob is up to 16 MiB).
const memLimit = 96 << 20

func newCache(dir string, limit int64) (*cache, error) {
	if err := os.MkdirAll(dir, 0o700); err != nil {
		return nil, err
	}
	c := &cache{dir: dir, limit: limit, mem: list.New(), memIdx: map[string]*list.Element{}}
	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil, err
	}
	for _, en := range entries {
		if info, err := en.Info(); err == nil && !en.IsDir() {
			c.size += info.Size()
		}
	}
	return c, nil
}

func (c *cache) path(id string) string { return filepath.Join(c.dir, id) }

func (c *cache) has(id string) bool {
	_, err := os.Stat(c.path(id))
	return err == nil
}

func (c *cache) get(id string) []byte {
	c.mu.Lock()
	if el, ok := c.memIdx[id]; ok {
		c.mem.MoveToFront(el)
		d := el.Value.(*memItem).data
		c.mu.Unlock()
		return d
	}
	c.mu.Unlock()
	d, err := os.ReadFile(c.path(id))
	if err != nil {
		return nil
	}
	now := time.Now()
	_ = os.Chtimes(c.path(id), now, now) // LRU order
	c.remember(id, d)
	return d
}

func (c *cache) remember(id string, d []byte) {
	c.mu.Lock()
	defer c.mu.Unlock()
	if el, ok := c.memIdx[id]; ok {
		c.mem.MoveToFront(el)
		return
	}
	c.memIdx[id] = c.mem.PushFront(&memItem{id, d})
	c.memLen += int64(len(d))
	for c.memLen > memLimit && c.mem.Len() > 1 {
		el := c.mem.Back()
		c.mem.Remove(el)
		c.memLen -= int64(len(el.Value.(*memItem).data))
		delete(c.memIdx, el.Value.(*memItem).id)
	}
}

// put stores a blob. With evict=false the limit is enforced later.
func (c *cache) put(id string, d []byte, _ bool) {
	c.remember(id, d)
	if c.has(id) {
		return
	}
	if err := writeFileAtomic(c.path(id), d); err != nil {
		return
	}
	c.mu.Lock()
	c.size += int64(len(d))
	over := c.size > c.limit
	c.mu.Unlock()
	if over {
		c.evict()
	}
}

// evict deletes the least recently used unpinned blobs until under limit.
func (c *cache) evict() {
	var keep map[string]bool
	if c.keep != nil {
		keep = c.keep()
	}
	entries, err := os.ReadDir(c.dir)
	if err != nil {
		return
	}
	type item struct {
		id   string
		size int64
		used time.Time
	}
	var items []item
	for _, en := range entries {
		info, err := en.Info()
		if err != nil || en.IsDir() || keep[en.Name()] {
			continue
		}
		items = append(items, item{en.Name(), info.Size(), info.ModTime()})
	}
	sort.Slice(items, func(i, j int) bool { return items[i].used.Before(items[j].used) })
	c.mu.Lock()
	defer c.mu.Unlock()
	for _, it := range items {
		if c.size <= c.limit {
			return
		}
		if os.Remove(c.path(it.id)) == nil {
			c.size -= it.size
			if el, ok := c.memIdx[it.id]; ok {
				c.mem.Remove(el)
				c.memLen -= int64(len(el.Value.(*memItem).data))
				delete(c.memIdx, it.id)
			}
		}
	}
}

// Size returns the bytes cached on disk.
func (c *cache) Size() int64 {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.size
}
