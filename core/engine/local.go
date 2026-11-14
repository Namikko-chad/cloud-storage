package engine

import (
	"context"
	"io"
	"io/fs"
	"os"
	"path"
	"path/filepath"
	"sort"
	"strings"

	"cloudsync/core/index"
)

// LocalUploads walks local files and directories and returns uploads that
// place them under remoteDir (a directory keeps its own name).
func LocalUploads(localPaths []string, remoteDir string) ([]Upload, error) {
	dst := index.Clean(remoteDir)
	var ups []Upload
	for _, src := range localPaths {
		base := filepath.Dir(filepath.Clean(src))
		err := filepath.WalkDir(src, func(p string, d fs.DirEntry, err error) error {
			if err != nil || d.IsDir() {
				return err
			}
			info, err := d.Info()
			if err != nil {
				return err
			}
			if !info.Mode().IsRegular() {
				return nil
			}
			rel, err := filepath.Rel(base, p)
			if err != nil {
				return err
			}
			local := p
			ups = append(ups, Upload{
				Path:    path.Join(dst, filepath.ToSlash(rel)),
				ModTime: info.ModTime(),
				Mode:    uint32(info.Mode().Perm()),
				Open:    func() (io.ReadCloser, error) { return os.Open(local) },
			})
			return nil
		})
		if err != nil {
			return nil, err
		}
	}
	sort.Slice(ups, func(i, j int) bool { return ups[i].Path < ups[j].Path })
	return ups, nil
}

// Download writes a file or a directory tree to local. If local is an
// existing directory, the item is placed inside it.
func (e *Engine) Download(ctx context.Context, remote, local string) error {
	en, err := e.Stat(remote)
	if err != nil {
		return err
	}
	if st, err := os.Stat(local); err == nil && st.IsDir() {
		local = filepath.Join(local, en.Name())
	}
	if !en.Dir {
		return e.downloadFile(ctx, en, local)
	}
	var files []index.Entry
	prefix := strings.TrimSuffix(en.Path, "/") + "/"
	e.idx.Walk(func(c index.Entry) {
		if strings.HasPrefix(c.Path, prefix) {
			files = append(files, c)
		}
	})
	if err := os.MkdirAll(local, 0o755); err != nil {
		return err
	}
	for _, f := range files {
		dst := filepath.Join(local, filepath.FromSlash(strings.TrimPrefix(f.Path, prefix)))
		if f.Dir {
			err = os.MkdirAll(dst, 0o755)
		} else {
			err = e.downloadFile(ctx, f, dst)
		}
		if err != nil {
			return err
		}
	}
	return nil
}

func (e *Engine) downloadFile(ctx context.Context, en index.Entry, local string) error {
	f, err := e.OpenFile(ctx, en.Path)
	if err != nil {
		return err
	}
	if err := os.MkdirAll(filepath.Dir(local), 0o755); err != nil {
		return err
	}
	tmp, err := os.CreateTemp(filepath.Dir(local), ".cs-download-*")
	if err != nil {
		return err
	}
	defer os.Remove(tmp.Name())
	if _, err := f.WriteTo(tmp); err != nil {
		tmp.Close()
		return err
	}
	if err := tmp.Close(); err != nil {
		return err
	}
	if err := os.Rename(tmp.Name(), local); err != nil {
		return err
	}
	return os.Chtimes(local, en.Version.ModTime, en.Version.ModTime)
}

// CacheBytes is the size of the local blob cache.
func (e *Engine) CacheBytes() int64 { return e.cache.Size() }
