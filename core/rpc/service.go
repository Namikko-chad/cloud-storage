// Package rpc serves the CloudSync gRPC API over an engine. The same
// service runs in the desktop daemon and inside the Android app.
package rpc

import (
	"context"
	"errors"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"time"

	rfs "github.com/rclone/rclone/fs"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"

	"cloudsync/core/backend"
	"cloudsync/core/crypto"
	"cloudsync/core/engine"
	"cloudsync/core/eventlog"
	"cloudsync/core/index"
	"cloudsync/core/lock"
	"cloudsync/core/rpc/pb"
	"cloudsync/core/secrets"
	"cloudsync/core/vault"
)

// Hooks let the host react to the vault being opened or closed (the
// desktop daemon mounts the folder).
type Hooks struct {
	// OnUnlock runs after the engine opened; it returns the mount point.
	OnUnlock func(e *engine.Engine) (string, error)
	// OnLock runs before the engine closes.
	OnLock func()
	// OnSync runs after every background sync.
	OnSync func(e *engine.Engine)
	// MountDir returns the configured mount folder; SetMountDir changes and
	// keeps it (the service unmounts before and mounts after). Nil: the
	// host cannot mount (Android).
	MountDir    func() string
	SetMountDir func(dir string) error
	// Shutdown stops the host process (desktop daemon); nil: not possible.
	Shutdown func()
}

// Service implements pb.CloudSyncServer.
type Service struct {
	pb.UnimplementedCloudSyncServer
	VaultPath string
	DataRoot  string // device data dirs are created inside
	Platform  string
	SyncEvery time.Duration
	Hooks     Hooks
	// Log keeps recent events for the app (storage failures, sync errors).
	Log *eventlog.Log

	mu    sync.Mutex
	v     *vault.Vault
	e     *engine.Engine
	mount string
	// The vault is open but the engine is not (too few storages yet, ...):
	// storages can still be added, then the engine opens.
	problem    string
	deviceName string
	reloadMu   sync.Mutex
	stop       chan struct{}
	stopped    chan struct{}

	subMu sync.Mutex
	subs  map[chan *pb.Event]struct{}
}

// NewService returns a locked service for the vault file at vaultPath.
func NewService(vaultPath, dataRoot, platform string) *Service {
	return &Service{
		VaultPath: vaultPath, DataRoot: dataRoot, Platform: platform,
		SyncEvery: 30 * time.Second,
		Log:       eventlog.New(1000, nil),
		subs:      map[chan *pb.Event]struct{}{},
	}
}

// TokenAuth returns interceptors that require metadata "authorization:
// Bearer <token>", so only processes that can read the token file connect.
func TokenAuth(token string) []grpc.ServerOption {
	check := func(ctx context.Context) error {
		md, _ := metadata.FromIncomingContext(ctx)
		for _, v := range md.Get("authorization") {
			if v == "Bearer "+token {
				return nil
			}
		}
		return status.Error(codes.Unauthenticated, "bad token")
	}
	return []grpc.ServerOption{
		grpc.UnaryInterceptor(func(ctx context.Context, req any, _ *grpc.UnaryServerInfo, h grpc.UnaryHandler) (any, error) {
			if err := check(ctx); err != nil {
				return nil, err
			}
			return h(ctx, req)
		}),
		grpc.StreamInterceptor(func(srv any, ss grpc.ServerStream, _ *grpc.StreamServerInfo, h grpc.StreamHandler) error {
			if err := check(ss.Context()); err != nil {
				return err
			}
			return h(srv, ss)
		}),
	}
}

// Engine returns the open engine, or an error while the vault is locked.
func (s *Service) Engine() (*engine.Engine, error) { return s.engine() }

// Subscribe calls fn for every event until the returned function is called.
func (s *Service) Subscribe(fn func(*pb.Event)) (cancel func()) {
	ch := make(chan *pb.Event, 16)
	done := make(chan struct{})
	s.subMu.Lock()
	s.subs[ch] = struct{}{}
	s.subMu.Unlock()
	go func() {
		for {
			select {
			case ev := <-ch:
				fn(ev)
			case <-done:
				return
			}
		}
	}()
	return func() {
		s.subMu.Lock()
		delete(s.subs, ch)
		s.subMu.Unlock()
		close(done)
	}
}

func (s *Service) engine() (*engine.Engine, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.e == nil {
		if s.v != nil {
			return nil, status.Error(codes.FailedPrecondition, "vault is not ready: "+s.problem)
		}
		return nil, status.Error(codes.FailedPrecondition, "vault is locked")
	}
	return s.e, nil
}

func toStatus(err error) error {
	var le *lock.LockedError
	switch {
	case err == nil:
		return nil
	case status.Code(err) != codes.Unknown:
		return err
	case errors.Is(err, fs.ErrNotExist):
		return status.Error(codes.NotFound, err.Error())
	case errors.Is(err, fs.ErrExist):
		return status.Error(codes.AlreadyExists, err.Error())
	case errors.Is(err, vault.ErrBadPassword):
		return status.Error(codes.PermissionDenied, err.Error())
	case errors.As(err, &le):
		return status.Error(codes.Aborted, err.Error())
	case errors.Is(err, engine.ErrIsDir), errors.Is(err, engine.ErrNotDir), errors.Is(err, engine.ErrNotEmpty):
		return status.Error(codes.FailedPrecondition, err.Error())
	case errors.Is(err, secrets.ErrInvalid):
		return status.Error(codes.InvalidArgument, err.Error())
	case errors.Is(err, context.Canceled):
		return status.Error(codes.Canceled, err.Error())
	}
	return status.Error(codes.Internal, err.Error())
}

func (s *Service) state() *pb.State {
	_, err := os.Stat(s.VaultPath)
	st := &pb.State{
		VaultExists: err == nil, VaultPath: s.VaultPath, MountPoint: s.mount, Platform: s.Platform,
		CoreVersion: Version, CoreBuild: Build,
	}
	if s.Hooks.SetMountDir != nil {
		st.CanMount = true
	}
	if s.Hooks.MountDir != nil {
		st.MountDir = s.Hooks.MountDir()
	}
	if s.v != nil {
		st.Unlocked = true
		st.VaultId = s.v.Config().VaultID
		st.DeviceName = s.deviceName
		st.Problem = s.problem
	}
	if s.e != nil {
		st.Ready = true
		st.VaultId = s.e.Config().VaultID
		st.DeviceId = s.e.DeviceID()
		st.DeviceName = s.e.Device().Name
	}
	return st
}

func (s *Service) GetState(context.Context, *pb.Empty) (*pb.State, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.state(), nil
}

func (s *Service) CreateVault(ctx context.Context, r *pb.CreateVaultRequest) (*pb.State, error) {
	if r.Password == "" {
		return nil, status.Error(codes.InvalidArgument, "empty password")
	}
	c, err := vault.New(int(r.DataShards), int(r.ParityShards))
	if err != nil {
		return nil, status.Error(codes.InvalidArgument, err.Error())
	}
	v, err := vault.Create(s.VaultPath, []byte(r.Password), c, vault.DefaultKDF)
	if err != nil {
		return nil, toStatus(err)
	}
	return s.open(ctx, v, r.DeviceName)
}

func (s *Service) ImportVault(ctx context.Context, r *pb.ImportVaultRequest) (*pb.State, error) {
	if _, err := os.Stat(s.VaultPath); err == nil {
		return nil, status.Error(codes.AlreadyExists, "a vault already exists on this device")
	}
	if _, err := vault.Decode(r.Vault, []byte(r.Password)); err != nil {
		return nil, toStatus(err)
	}
	if err := os.MkdirAll(filepath.Dir(s.VaultPath), 0o700); err != nil {
		return nil, toStatus(err)
	}
	if err := os.WriteFile(s.VaultPath, r.Vault, 0o600); err != nil {
		return nil, toStatus(err)
	}
	v, err := vault.Open(s.VaultPath, []byte(r.Password))
	if err != nil {
		return nil, toStatus(err)
	}
	return s.open(ctx, v, r.DeviceName)
}

func (s *Service) Unlock(ctx context.Context, r *pb.UnlockRequest) (*pb.State, error) {
	s.mu.Lock()
	if s.e != nil {
		defer s.mu.Unlock()
		return s.state(), nil
	}
	notReady := s.v != nil
	s.mu.Unlock()
	if notReady {
		s.reload(ctx)
		s.mu.Lock()
		defer s.mu.Unlock()
		return s.state(), nil
	}
	v, err := vault.Open(s.VaultPath, []byte(r.Password))
	if err != nil {
		return nil, toStatus(err)
	}
	return s.open(ctx, v, r.DeviceName)
}

// OpenWith unlocks with an already opened vault (daemon started with a
// password from the environment).
func (s *Service) OpenWith(ctx context.Context, v *vault.Vault, deviceName string) error {
	_, err := s.open(ctx, v, deviceName)
	return err
}

func (s *Service) open(ctx context.Context, v *vault.Vault, deviceName string) (*pb.State, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.e != nil {
		return s.state(), nil
	}
	dir := filepath.Join(s.DataRoot, "data-"+v.Config().VaultID[:8])
	s.v, s.deviceName = v, deviceName
	e, err := engine.Open(ctx, v, engine.Options{DataDir: dir, DeviceName: deviceName, Platform: s.Platform, Log: s.Log})
	if err != nil {
		// Unlocked but not ready: the app shows the problem and lets the
		// user add storages; every vault change retries.
		s.problem = err.Error()
		s.Log.Add(eventlog.Warn, "vault", "", "not ready: "+err.Error())
		s.publish(pb.Event_STATE_CHANGED, "")
		return s.state(), nil
	}
	s.e, s.problem = e, ""
	if s.Hooks.OnUnlock != nil {
		mp, err := s.Hooks.OnUnlock(e)
		if err != nil {
			s.Log.Add(eventlog.Error, "mount", "", err.Error())
			s.publish(pb.Event_SYNC_ERROR, "mount: "+err.Error())
		} else if mp != "" {
			s.Log.Add(eventlog.Info, "mount", "", "mounted at "+mp)
		}
		s.mount = mp
	}
	s.Log.Add(eventlog.Info, "vault", "", "opened")
	go s.fillAccounts(v)
	s.stop, s.stopped = make(chan struct{}), make(chan struct{})
	go s.loop(s.stop, s.stopped)
	s.publish(pb.Event_STATE_CHANGED, "")
	return s.state(), nil
}

func (s *Service) LockVault(ctx context.Context, _ *pb.Empty) (*pb.State, error) {
	s.close(ctx)
	s.mu.Lock()
	defer s.mu.Unlock()
	s.publish(pb.Event_STATE_CHANGED, "")
	return s.state(), nil
}

// Close locks the vault (used on shutdown).
func (s *Service) Close(ctx context.Context) { s.close(ctx) }

func (s *Service) close(ctx context.Context) { s.closeEngine(ctx, false) }

// closeEngine stops the engine; with keepVault the vault stays open (a
// reload), so calls meanwhile fail with "not ready" rather than "locked".
func (s *Service) closeEngine(ctx context.Context, keepVault bool) {
	s.mu.Lock()
	stop, stopped := s.stop, s.stopped
	s.stop = nil
	s.mu.Unlock()
	if stop != nil {
		close(stop)
		<-stopped
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.e != nil {
		if s.Hooks.OnLock != nil {
			s.Hooks.OnLock()
		}
		s.e.Close(ctx)
		s.e, s.mount = nil, ""
	}
	if keepVault {
		s.problem = "reopening with the changed vault"
	} else {
		s.v, s.problem = nil, ""
	}
}

// loop syncs periodically. When the vault changed elsewhere (a storage
// was added), the engine is reopened with the new config.
func (s *Service) loop(stop, stopped chan struct{}) {
	defer close(stopped)
	t := time.NewTicker(s.SyncEvery)
	defer t.Stop()
	for {
		s.syncOnce(context.Background())
		select {
		case <-stop:
			return
		case <-t.C:
		}
	}
}

func (s *Service) syncOnce(ctx context.Context) {
	e, err := s.engine()
	if err != nil {
		return
	}
	before := e.Index().Len()
	err = e.Sync(ctx)
	if s.Hooks.OnSync != nil {
		s.Hooks.OnSync(e)
	}
	if e.Index().Len() != before {
		s.publish(pb.Event_TREE_CHANGED, "")
	}
	if err != nil {
		s.Log.Add(eventlog.Error, "sync", "", err.Error())
		s.publish(pb.Event_SYNC_ERROR, eventlog.Clean(err.Error()))
	} else {
		s.publish(pb.Event_SYNC_DONE, "")
	}
	if e.ReloadNeeded() {
		go s.reload(ctx)
	}
}

func (s *Service) reload(ctx context.Context) {
	s.reloadMu.Lock()
	defer s.reloadMu.Unlock()
	s.mu.Lock()
	v, e, name := s.v, s.e, s.deviceName
	s.mu.Unlock()
	if v == nil {
		return
	}
	if e != nil {
		name = e.Device().Name
	}
	s.closeEngine(ctx, true)
	if _, err := s.open(ctx, v, name); err != nil {
		s.Log.Add(eventlog.Error, "vault", "", "reopen: "+err.Error())
		s.publish(pb.Event_SYNC_ERROR, "reopen: "+err.Error())
	}
}

func (s *Service) ChangePassword(_ context.Context, r *pb.ChangePasswordRequest) (*pb.Empty, error) {
	s.mu.Lock()
	v := s.v
	s.mu.Unlock()
	if v == nil {
		return nil, status.Error(codes.FailedPrecondition, "vault is locked")
	}
	if _, err := vault.Open(s.VaultPath, []byte(r.OldPassword)); err != nil {
		return nil, toStatus(err)
	}
	if r.NewPassword == "" {
		return nil, status.Error(codes.InvalidArgument, "empty password")
	}
	return &pb.Empty{}, toStatus(v.ChangePassword([]byte(r.NewPassword), vault.DefaultKDF))
}

func (s *Service) CheckPassword(_ context.Context, r *pb.CheckPasswordRequest) (*pb.Empty, error) {
	if _, err := vault.Open(s.VaultPath, []byte(r.Password)); err != nil {
		return nil, toStatus(err)
	}
	return &pb.Empty{}, nil
}

func (s *Service) ExportVault(context.Context, *pb.Empty) (*pb.VaultFile, error) {
	if _, err := s.engine(); err != nil {
		return nil, err
	}
	data, err := os.ReadFile(s.VaultPath)
	return &pb.VaultFile{Vault: data}, toStatus(err)
}

func (s *Service) BackendTypes(context.Context, *pb.Empty) (*pb.BackendTypesReply, error) {
	out := &pb.BackendTypesReply{}
	for _, name := range backend.Types() {
		info, err := rfs.Find(name)
		if err != nil {
			continue
		}
		t := &pb.BackendType{Name: info.Name, Description: info.Description}
		for _, o := range info.Options {
			if o.Hide != 0 {
				continue
			}
			if o.Name == "token" {
				t.Oauth = true
			}
			opt := &pb.BackendOption{
				Name: o.Name, Help: o.Help, Required: o.Required, Password: o.IsPassword, Advanced: o.Advanced,
			}
			if o.Default != nil {
				opt.Default = fmt.Sprint(o.Default)
			}
			for _, ex := range o.Examples {
				opt.Examples = append(opt.Examples, ex.Value)
			}
			t.Options = append(t.Options, opt)
		}
		out.Types = append(out.Types, t)
	}
	return out, nil
}

func (s *Service) AddBackend(ctx context.Context, r *pb.AddBackendRequest) (*pb.Backend, error) {
	s.mu.Lock()
	v := s.v
	s.mu.Unlock()
	if v == nil {
		return nil, status.Error(codes.FailedPrecondition, "vault is locked")
	}
	if r.Name == "" || r.Type == "" {
		return nil, status.Error(codes.InvalidArgument, "name and type are required")
	}
	params, err := backend.ObscureParams(r.Type, r.Params)
	if err != nil {
		return nil, status.Error(codes.InvalidArgument, err.Error())
	}
	if params, err = backend.CompleteParams(ctx, r.Type, params); err != nil {
		return nil, status.Error(codes.Unavailable, err.Error())
	}
	root := r.Root
	if root == "" {
		root = "cloudsync"
	}
	if err := backend.CheckRoot(r.Type, root); err != nil {
		return nil, status.Error(codes.InvalidArgument, err.Error())
	}
	b := vault.Backend{ID: crypto.RandomID(6), Name: r.Name, Type: r.Type, Domain: r.Domain, Root: root, Params: params}
	b.Account = strings.TrimSpace(r.Account)
	if b.Account == "" {
		b.Account = backend.AccountFromParams(b.Type, b.Params)
	}
	if b.Account == "" && b.Params["token"] != "" {
		b.Account, _ = backend.WhoAmI(ctx, b.Type, b.Params)
	}
	if err := sameLocation(v.Config(), b); err != nil {
		return nil, err
	}
	st, err := backend.OpenRclone(ctx, v.Config().VaultID, backend.SharePacing(b, v.Config().Backends), nil)
	if err != nil {
		return nil, status.Error(codes.InvalidArgument, err.Error())
	}
	if _, err := st.ListDirs(ctx, "j"); err != nil {
		return nil, status.Error(codes.Unavailable, "storage not reachable: "+err.Error())
	}
	if err := v.Update(func(c *vault.Config) error {
		if err := sameLocation(c, b); err != nil {
			return err
		}
		c.Backends = append(c.Backends, b)
		return nil
	}); err != nil {
		return nil, toStatus(err)
	}
	s.Log.Addf(eventlog.Info, "storage", b.ID, "%s: added (%s)", b.Name, firstNonEmpty(b.Account, b.Type))
	go s.reload(context.Background())
	return &pb.Backend{
		Id: b.ID, Name: b.Name, Type: b.Type, Domain: b.FailureDomain(), Enabled: true, Online: true,
		Account: b.Account, Root: b.Root,
	}, nil
}

// sameLocation refuses a storage in the same place as one already in the
// vault: it would add no redundancy, and two storages sharing a folder see
// each other's objects.
func sameLocation(c *vault.Config, b vault.Backend) error {
	for _, o := range c.Backends {
		if backend.SameLocation(o, b) {
			what := "account " + backend.AccountOf(o)
			if b.Type == "local" {
				what = "folder " + o.Root
			}
			return status.Errorf(codes.AlreadyExists, "storage %q already uses this %s; one account or folder can hold only one storage", o.Name, what)
		}
	}
	return nil
}

func firstNonEmpty(s ...string) string {
	for _, x := range s {
		if x != "" {
			return x
		}
	}
	return ""
}

// fillAccounts records the account of OAuth storages added before accounts
// were kept (once; it needs a valid access token, so it may take a later
// open).
func (s *Service) fillAccounts(v *vault.Vault) {
	for _, b := range v.Config().Backends {
		if b.Account != "" || backend.AccountFromParams(b.Type, b.Params) != "" || b.Params["token"] == "" {
			continue
		}
		acc, err := backend.WhoAmI(context.Background(), b.Type, b.Params)
		if err != nil || acc == "" {
			continue
		}
		_ = v.Update(func(c *vault.Config) error {
			for i := range c.Backends {
				if c.Backends[i].ID == b.ID && c.Backends[i].Account == "" {
					c.Backends[i].Account = acc
				}
			}
			return nil
		})
	}
}

// backendInfo adds what the vault knows about b (account, folder, other
// storages in the same place) to its status.
func backendInfo(cfg *vault.Config, out *pb.Backend) {
	b, ok := cfg.Backend(out.Id)
	if !ok {
		return
	}
	out.Account = backend.AccountOf(b)
	if b.Type == "local" {
		out.Account = b.Root
	}
	out.Root = b.Root
	out.Oauth = backend.HasSignIn(b.Type)
	for _, o := range cfg.Backends {
		if o.ID != b.ID && backend.SameLocation(o, b) {
			out.SameAs = o.ID
			break
		}
	}
}

func (s *Service) RenameBackend(_ context.Context, r *pb.RenameBackendRequest) (*pb.Backend, error) {
	s.mu.Lock()
	v := s.v
	s.mu.Unlock()
	if v == nil {
		return nil, status.Error(codes.FailedPrecondition, "vault is locked")
	}
	name := strings.TrimSpace(r.Name)
	if name == "" {
		return nil, status.Error(codes.InvalidArgument, "empty name")
	}
	var out vault.Backend
	old := ""
	err := v.Update(func(c *vault.Config) error {
		for i := range c.Backends {
			if c.Backends[i].ID == r.Id {
				old = c.Backends[i].Name
				c.Backends[i].Name = name
				out = c.Backends[i]
				return nil
			}
		}
		return fmt.Errorf("backend %s: %w", r.Id, fs.ErrNotExist)
	})
	if err != nil {
		return nil, toStatus(err)
	}
	s.Log.Addf(eventlog.Info, "storage", out.ID, "renamed %q to %q", old, name)
	pbb := &pb.Backend{Id: out.ID, Name: out.Name, Type: out.Type, Domain: out.FailureDomain(), Enabled: !out.Disabled}
	backendInfo(v.Config(), pbb)
	return pbb, nil
}

// Shutdown stops the daemon after the reply is sent.
func (s *Service) Shutdown(context.Context, *pb.Empty) (*pb.Empty, error) {
	if s.Hooks.Shutdown == nil {
		return nil, status.Error(codes.Unimplemented, "the core cannot be stopped from here")
	}
	s.Log.Add(eventlog.Info, "vault", "", "stop requested from the app")
	go func() {
		time.Sleep(200 * time.Millisecond)
		s.Hooks.Shutdown()
	}()
	return &pb.Empty{}, nil
}

func (s *Service) SetBackendEnabled(_ context.Context, r *pb.SetBackendEnabledRequest) (*pb.Backend, error) {
	s.mu.Lock()
	v := s.v
	s.mu.Unlock()
	if v == nil {
		return nil, status.Error(codes.FailedPrecondition, "vault is locked")
	}
	var out vault.Backend
	err := v.Update(func(c *vault.Config) error {
		for i := range c.Backends {
			if c.Backends[i].ID == r.Id {
				c.Backends[i].Disabled = !r.Enabled
				out = c.Backends[i]
				return nil
			}
		}
		return fmt.Errorf("backend %s: %w", r.Id, fs.ErrNotExist)
	})
	if err != nil {
		return nil, toStatus(err)
	}
	go s.reload(context.Background())
	return &pb.Backend{Id: out.ID, Name: out.Name, Type: out.Type, Domain: out.FailureDomain(), Enabled: !out.Disabled}, nil
}

func (s *Service) Status(ctx context.Context, _ *pb.Empty) (*pb.StatusReply, error) {
	e, err := s.engine()
	if err != nil {
		s.mu.Lock()
		v := s.v
		s.mu.Unlock()
		if v == nil {
			return nil, err
		}
		return configStatus(v.Config()), nil
	}
	st := e.Status(ctx)
	out := &pb.StatusReply{
		DataShards: int32(st.DataShards), ParityShards: int32(st.ParityShards),
		Pending: int32(st.Pending), ReloadNeeded: st.ReloadNeeded, DomainRisk: st.DomainRisk,
		CacheBytes: e.CacheBytes(), Pins: e.Pins(), DeviceId: e.DeviceID(),
	}
	cfg := e.Config()
	// Storages are listed from the vault, which may be newer than the
	// engine (one just added or renamed): those the engine has not opened
	// yet show as preparing until it reopens.
	vcfg := cfg
	s.mu.Lock()
	if s.v != nil {
		vcfg = s.v.Config()
		out.VaultVersion = vcfg.Version
	}
	s.mu.Unlock()
	space := map[string]engine.BackendSpace{}
	sp := e.Space(ctx)
	for _, b := range sp.Backends {
		space[b.ID] = b
	}
	out.FilesBytes = sp.Files
	if sp.Writable >= 0 {
		out.WritableBytes = &sp.Writable
	}
	live := map[string]engine.BackendStatus{}
	for _, b := range st.Backends {
		live[b.ID] = b
	}
	for _, vb := range vcfg.Backends {
		pbb := &pb.Backend{Id: vb.ID, Name: vb.Name, Type: vb.Type, Domain: vb.FailureDomain(), Enabled: !vb.Disabled}
		if b, ok := live[vb.ID]; ok {
			pbb.Online, pbb.Behind, pbb.Error = b.Online, b.Behind, b.Error
			pbb.GetMs, pbb.PutMs, pbb.ListMs = int32(b.Get.Milliseconds()), int32(b.Put.Milliseconds()), int32(b.List.Milliseconds())
		} else {
			pbb.Preparing = true
		}
		if b, ok := space[vb.ID]; ok {
			pbb.StoredBytes = b.Stored
			if b.Known {
				pbb.FreeBytes = &b.Free
				if b.Total >= 0 {
					pbb.TotalBytes = &b.Total
				}
			}
		}
		backendInfo(vcfg, pbb)
		out.Backends = append(out.Backends, pbb)
	}
	for _, d := range cfg.Devices {
		out.Devices = append(out.Devices, &pb.Device{Id: d.ID, Name: d.Name, Platform: d.Platform, AddedUnix: d.Added.Unix()})
	}
	return out, nil
}

// configStatus describes a vault whose engine is not open.
func configStatus(cfg *vault.Config) *pb.StatusReply {
	out := &pb.StatusReply{
		DataShards: int32(cfg.DataShards), ParityShards: int32(cfg.ParityShards),
		DomainRisk: engine.DomainRisk(cfg), VaultVersion: cfg.Version,
	}
	for _, b := range cfg.Backends {
		pbb := &pb.Backend{
			Id: b.ID, Name: b.Name, Type: b.Type, Domain: b.FailureDomain(), Enabled: !b.Disabled, Error: "not checked",
		}
		backendInfo(cfg, pbb)
		out.Backends = append(out.Backends, pbb)
	}
	for _, d := range cfg.Devices {
		out.Devices = append(out.Devices, &pb.Device{Id: d.ID, Name: d.Name, Platform: d.Platform, AddedUnix: d.Added.Unix()})
	}
	return out
}

func (s *Service) entry(e *engine.Engine, en index.Entry) *pb.Entry {
	out := &pb.Entry{
		Path: en.Path, Name: en.Name(), Dir: en.Dir, Pinned: e.IsPinned(en.Path), Device: en.Device,
		ConflictOf: en.ConflictOf,
	}
	if en.Path == "/" {
		out.Name = ""
	}
	if en.Version != nil {
		out.Size = en.Version.Size
		out.MtimeUnix = en.Version.ModTime.Unix()
		out.Local = e.IsLocal(en.Path)
	} else {
		out.MtimeUnix = en.Time.Unix()
	}
	return out
}

func (s *Service) List(_ context.Context, r *pb.PathRequest) (*pb.ListReply, error) {
	e, err := s.engine()
	if err != nil {
		return nil, err
	}
	list, err := e.List(r.Path)
	if err != nil {
		return nil, toStatus(err)
	}
	sort.SliceStable(list, func(i, j int) bool {
		if list[i].Dir != list[j].Dir {
			return list[i].Dir
		}
		return strings.ToLower(list[i].Name()) < strings.ToLower(list[j].Name())
	})
	out := &pb.ListReply{}
	for _, en := range list {
		out.Entries = append(out.Entries, s.entry(e, en))
	}
	return out, nil
}

func (s *Service) Stat(_ context.Context, r *pb.PathRequest) (*pb.Entry, error) {
	e, err := s.engine()
	if err != nil {
		return nil, err
	}
	en, err := e.Stat(r.Path)
	if err != nil {
		return nil, toStatus(err)
	}
	return s.entry(e, en), nil
}

func (s *Service) changed() { s.publish(pb.Event_TREE_CHANGED, "") }

func (s *Service) Mkdir(ctx context.Context, r *pb.PathRequest) (*pb.Empty, error) {
	e, err := s.engine()
	if err != nil {
		return nil, err
	}
	if err := e.Mkdir(ctx, r.Path); err != nil {
		return nil, toStatus(err)
	}
	s.changed()
	return &pb.Empty{}, nil
}

func (s *Service) Remove(ctx context.Context, r *pb.RemoveRequest) (*pb.Empty, error) {
	e, err := s.engine()
	if err != nil {
		return nil, err
	}
	if h, err := e.LockHolder(ctx, r.Path); err == nil && h != nil && h.Device != e.DeviceID() {
		return nil, toStatus(&lock.LockedError{Path: r.Path, Holder: *h})
	}
	if err := e.Remove(ctx, r.Path, r.Recursive); err != nil {
		return nil, toStatus(err)
	}
	s.changed()
	return &pb.Empty{}, nil
}

func (s *Service) Rename(ctx context.Context, r *pb.RenameRequest) (*pb.Empty, error) {
	e, err := s.engine()
	if err != nil {
		return nil, err
	}
	if h, err := e.LockHolder(ctx, r.From); err == nil && h != nil && h.Device != e.DeviceID() {
		return nil, toStatus(&lock.LockedError{Path: r.From, Holder: *h})
	}
	if err := e.Rename(ctx, r.From, r.To); err != nil {
		return nil, toStatus(err)
	}
	s.changed()
	return &pb.Empty{}, nil
}

func (s *Service) Upload(ctx context.Context, r *pb.UploadRequest) (*pb.UploadReply, error) {
	e, err := s.engine()
	if err != nil {
		return nil, err
	}
	ups, err := engine.LocalUploads(r.LocalPaths, r.RemoteDir)
	if err != nil {
		return nil, toStatus(err)
	}
	out, err := e.PutFiles(ctx, ups)
	if err != nil {
		return nil, toStatus(err)
	}
	s.changed()
	return &pb.UploadReply{Files: int32(len(out))}, nil
}

func (s *Service) Download(ctx context.Context, r *pb.DownloadRequest) (*pb.Empty, error) {
	e, err := s.engine()
	if err != nil {
		return nil, err
	}
	return &pb.Empty{}, toStatus(e.Download(ctx, r.Path, r.LocalPath))
}

func (s *Service) Pin(ctx context.Context, r *pb.PathRequest) (*pb.Empty, error) {
	e, err := s.engine()
	if err != nil {
		return nil, err
	}
	err = e.Pin(ctx, r.Path)
	s.changed()
	return &pb.Empty{}, toStatus(err)
}

func (s *Service) Unpin(_ context.Context, r *pb.PathRequest) (*pb.Empty, error) {
	e, err := s.engine()
	if err != nil {
		return nil, err
	}
	err = e.Unpin(r.Path)
	s.changed()
	return &pb.Empty{}, toStatus(err)
}

func (s *Service) LockHolder(ctx context.Context, r *pb.PathRequest) (*pb.LockInfo, error) {
	e, err := s.engine()
	if err != nil {
		return nil, err
	}
	h, err := e.LockHolder(ctx, r.Path)
	if err != nil {
		return nil, status.Error(codes.Unavailable, err.Error())
	}
	if h == nil {
		return &pb.LockInfo{}, nil
	}
	return &pb.LockInfo{
		Locked: true, DeviceId: h.Device, DeviceName: h.DeviceName,
		SinceUnix: h.Created.Unix(), Mine: h.Device == e.DeviceID(),
	}, nil
}

func (s *Service) Sync(ctx context.Context, _ *pb.Empty) (*pb.Empty, error) {
	if _, err := s.engine(); err != nil {
		return nil, err
	}
	s.syncOnce(ctx)
	return &pb.Empty{}, nil
}

func (s *Service) Watch(_ *pb.Empty, stream pb.CloudSync_WatchServer) error {
	ch := make(chan *pb.Event, 16)
	s.subMu.Lock()
	s.subs[ch] = struct{}{}
	s.subMu.Unlock()
	defer func() {
		s.subMu.Lock()
		delete(s.subs, ch)
		s.subMu.Unlock()
	}()
	for {
		select {
		case <-stream.Context().Done():
			return nil
		case ev := <-ch:
			if err := stream.Send(ev); err != nil {
				return err
			}
		}
	}
}

func (s *Service) publish(kind pb.Event_Kind, msg string) {
	ev := &pb.Event{Kind: kind, Message: msg}
	s.subMu.Lock()
	defer s.subMu.Unlock()
	for ch := range s.subs {
		select {
		case ch <- ev:
		default: // slow client: drop, it will refresh on the next event
		}
	}
}

func (s *Service) Logs(_ context.Context, r *pb.LogsRequest) (*pb.LogsReply, error) {
	out := &pb.LogsReply{}
	for _, e := range s.Log.Entries(r.BackendId, int(r.Limit)) {
		out.Entries = append(out.Entries, &pb.LogEntry{
			Seq: e.Seq, TimeUnixMs: e.Time.UnixMilli(), FirstUnixMs: e.First.UnixMilli(),
			Level: e.Level, Source: e.Source, BackendId: e.BackendID, Message: e.Message, Count: int32(e.Count),
		})
	}
	return out, nil
}

func (s *Service) ClearLogs(context.Context, *pb.Empty) (*pb.Empty, error) {
	s.Log.Clear()
	return &pb.Empty{}, nil
}

// SetMountPoint changes the folder the vault is shown in and remounts.
func (s *Service) SetMountPoint(ctx context.Context, r *pb.PathRequest) (*pb.State, error) {
	if s.Hooks.SetMountDir == nil {
		return nil, status.Error(codes.Unimplemented, "this device cannot show the vault as a folder")
	}
	dir := strings.TrimSpace(r.Path)
	if dir != "" && !filepath.IsAbs(dir) {
		return nil, status.Errorf(codes.InvalidArgument, "the folder must be an absolute path, got %q", dir)
	}
	s.reloadMu.Lock() // no reopen while the folder moves
	defer s.reloadMu.Unlock()
	s.mu.Lock()
	e := s.e
	s.mu.Unlock()
	if e != nil && s.Hooks.OnLock != nil {
		s.Hooks.OnLock()
		s.mu.Lock()
		s.mount = ""
		s.mu.Unlock()
	}
	if err := s.Hooks.SetMountDir(dir); err != nil {
		return nil, toStatus(err)
	}
	var mountErr error
	if e != nil && s.Hooks.OnUnlock != nil {
		mp, err := s.Hooks.OnUnlock(e)
		if err != nil {
			mountErr = err
			s.Log.Add(eventlog.Error, "mount", "", err.Error())
		} else if mp != "" {
			s.Log.Add(eventlog.Info, "mount", "", "mounted at "+mp)
		}
		s.mu.Lock()
		s.mount = mp
		s.mu.Unlock()
	}
	s.publish(pb.Event_STATE_CHANGED, "")
	if mountErr != nil {
		return nil, status.Error(codes.FailedPrecondition, "folder saved, but mounting failed: "+mountErr.Error())
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.state(), nil
}
