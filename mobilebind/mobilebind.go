// Package mobilebind runs the core inside the Android app. It is built with
// "gomobile bind" into an AAR. The Kotlin side starts it from a foreground
// service; the Flutter UI talks to it over the same gRPC API as on
// desktops (a unix socket in the app's private files dir), and the
// DocumentsProvider uses the small file API below to show the vault in the
// system file picker.
package mobilebind

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net"
	"os"
	"path/filepath"
	"sync"
	"time"

	rconfig "github.com/rclone/rclone/fs/config"
	"google.golang.org/grpc"

	"cloudsync/core/crypto"
	"cloudsync/core/engine"
	"cloudsync/core/index"
	"cloudsync/core/lock"
	"cloudsync/core/rpc"
	"cloudsync/core/rpc/pb"
)

// Listener gets core events (implemented in Kotlin).
type Listener interface {
	// OnEvent: kind is 1 tree changed, 2 state changed, 3 sync done,
	// 4 sync error (see Event.Kind in cloudsync.proto).
	OnEvent(kind int, message string)
}

var (
	mu       sync.Mutex
	svc      *rpc.Service
	srv      *grpc.Server
	token    string
	sockPath string
	unsub    func()
	locks    = map[string]*lock.Lock{}
)

// Start runs the core: the vault lives in dataDir/vault.cs, device state
// next to it, temporary files go to cacheDir, and gRPC listens on the unix
// socket sock. It returns the bearer token clients must send. Calling it
// again returns the same token.
func Start(dataDir, cacheDir, sock string) (string, error) {
	mu.Lock()
	defer mu.Unlock()
	if svc != nil {
		return token, nil
	}
	if err := os.MkdirAll(dataDir, 0o700); err != nil {
		return "", err
	}
	// Android has no HOME and its default temp dir is not writable by apps.
	os.Setenv("HOME", dataDir)
	if cacheDir != "" {
		os.MkdirAll(cacheDir, 0o700)
		os.Setenv("TMPDIR", cacheDir)
	}
	// rclone's own config file is never used (storages are configured from
	// the vault), but keep it out of the read-only working directory.
	_ = rconfig.SetConfigPath(filepath.Join(dataDir, "rclone.conf"))
	os.Remove(sock)
	lis, err := net.Listen("unix", sock)
	if err != nil {
		return "", err
	}
	os.Chmod(sock, 0o600)
	s := rpc.NewService(filepath.Join(dataDir, "vault.cs"), dataDir, "android")
	token = crypto.RandomID(32)
	srv = grpc.NewServer(rpc.TokenAuth(token)...)
	pb.RegisterCloudSyncServer(srv, s)
	go srv.Serve(lis)
	svc, sockPath = s, sock
	return token, nil
}

// SetListener registers l for core events (nil to stop).
func SetListener(l Listener) {
	mu.Lock()
	defer mu.Unlock()
	if unsub != nil {
		unsub()
		unsub = nil
	}
	if l != nil && svc != nil {
		unsub = svc.Subscribe(func(ev *pb.Event) { l.OnEvent(int(ev.Kind), ev.Message) })
	}
}

// Stop locks the vault and stops the server.
func Stop() {
	mu.Lock()
	defer mu.Unlock()
	if svc == nil {
		return
	}
	if unsub != nil {
		unsub()
		unsub = nil
	}
	for p, l := range locks {
		l.Release(context.Background())
		delete(locks, p)
	}
	svc.Close(context.Background())
	srv.Stop()
	os.Remove(sockPath)
	svc, srv = nil, nil
}

func eng() (*engine.Engine, error) {
	mu.Lock()
	s := svc
	mu.Unlock()
	if s == nil {
		return nil, errors.New("core not started")
	}
	return s.Engine()
}

// Unlocked reports whether the vault is open.
func Unlocked() bool {
	_, err := eng()
	return err == nil
}

// Entry is what the file API returns, as JSON.
type Entry struct {
	Path     string `json:"path"`
	Name     string `json:"name"`
	Dir      bool   `json:"dir"`
	Size     int64  `json:"size"`
	Modified int64  `json:"mtime_ms"`
}

func toEntry(en index.Entry) Entry {
	out := Entry{Path: en.Path, Name: en.Name(), Dir: en.Dir, Modified: en.Time.UnixMilli()}
	if en.Path == "/" {
		out.Name = "CloudSync"
	}
	if en.Version != nil {
		out.Size = en.Version.Size
		out.Modified = en.Version.ModTime.UnixMilli()
	}
	return out
}

// List returns the children of dir as a JSON array of Entry.
func List(dir string) (string, error) {
	e, err := eng()
	if err != nil {
		return "", err
	}
	list, err := e.List(dir)
	if err != nil {
		return "", err
	}
	out := make([]Entry, len(list))
	for i, en := range list {
		out[i] = toEntry(en)
	}
	b, err := json.Marshal(out)
	return string(b), err
}

// Stat returns one Entry as JSON.
func Stat(p string) (string, error) {
	e, err := eng()
	if err != nil {
		return "", err
	}
	en, err := e.Stat(p)
	if err != nil {
		return "", err
	}
	b, err := json.Marshal(toEntry(en))
	return string(b), err
}

// ReadAt reads up to n bytes of file p at off; fewer at the end of file.
// Only the chunks touched are downloaded, and they stay in the cache.
func ReadAt(p string, off int64, n int) ([]byte, error) {
	e, err := eng()
	if err != nil {
		return nil, err
	}
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()
	f, err := e.OpenFile(ctx, p)
	if err != nil {
		return nil, err
	}
	buf := make([]byte, n)
	k, err := f.ReadAt(buf, off)
	if err == io.EOF {
		err = nil
	}
	return buf[:k], err
}

// Download writes file p to the local path dst (for "rw" opens).
func Download(p, dst string) error {
	e, err := eng()
	if err != nil {
		return err
	}
	return e.Download(context.Background(), p, dst)
}

// Lock takes the write lock for p, for an editor opening it. It fails if
// another device has it open. Locking an already locked path is a no-op.
func Lock(p string) error {
	e, err := eng()
	if err != nil {
		return err
	}
	p = index.Clean(p)
	mu.Lock()
	_, held := locks[p]
	mu.Unlock()
	if held {
		return nil
	}
	l, err := e.Lock(context.Background(), p)
	if errors.Is(err, lock.ErrNoQuorum) {
		return nil // offline: edit anyway, a conflict copy keeps both
	}
	if err != nil {
		return err
	}
	mu.Lock()
	locks[p] = l
	mu.Unlock()
	return nil
}

// Unlock releases the write lock taken by Lock.
func Unlock(p string) {
	p = index.Clean(p)
	mu.Lock()
	l := locks[p]
	delete(locks, p)
	mu.Unlock()
	if l != nil {
		l.Release(context.Background())
	}
}

// PutFile uploads the local file src as p (the editor saved it).
func PutFile(p, src string) error {
	e, err := eng()
	if err != nil {
		return err
	}
	f, err := os.Open(src)
	if err != nil {
		return err
	}
	defer f.Close()
	info, err := f.Stat()
	if err != nil {
		return err
	}
	_, err = e.PutFile(context.Background(), p, f, info.ModTime())
	return err
}

// Mkdir creates a directory.
func Mkdir(p string) error {
	e, err := eng()
	if err != nil {
		return err
	}
	return e.Mkdir(context.Background(), p)
}

// Remove deletes a file or a directory tree.
func Remove(p string) error {
	e, err := eng()
	if err != nil {
		return err
	}
	return e.Remove(context.Background(), p, true)
}

// Rename moves a file or directory.
func Rename(from, to string) error {
	e, err := eng()
	if err != nil {
		return err
	}
	return e.Rename(context.Background(), from, to)
}
