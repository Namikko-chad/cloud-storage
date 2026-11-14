package rpc

import (
	"context"
	"os"
	"path/filepath"
	"testing"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"cloudsync/core/rpc/pb"
	"cloudsync/core/vault"
)

func TestSetupFlow(t *testing.T) {
	vault.DefaultKDF = vault.KDFParams{Time: 1, Memory: 1024, Threads: 1}
	ctx := context.Background()
	dir := t.TempDir()
	s := NewService(filepath.Join(dir, "vault.cs"), dir, "linux")
	s.SyncEvery = time.Hour
	t.Cleanup(func() { s.Close(ctx) })

	st, err := s.CreateVault(ctx, &pb.CreateVaultRequest{Password: "pw", DataShards: 2, ParityShards: 1, DeviceName: "laptop"})
	if err != nil {
		t.Fatal(err)
	}
	if !st.Unlocked || st.Ready || st.Problem == "" {
		t.Fatalf("new vault without storages: %+v", st)
	}
	if _, err := s.CheckPassword(ctx, &pb.CheckPasswordRequest{Password: "pw"}); err != nil {
		t.Fatalf("right password: %v", err)
	}
	if _, err := s.CheckPassword(ctx, &pb.CheckPasswordRequest{Password: "nope"}); status.Code(err) != codes.PermissionDenied {
		t.Fatalf("wrong password: %v", err)
	}
	if rep, err := s.Status(ctx, &pb.Empty{}); err != nil || rep.DataShards != 2 {
		t.Fatalf("status while not ready: %v %v", rep, err)
	}
	if _, err := s.List(ctx, &pb.PathRequest{Path: "/"}); err == nil {
		t.Fatal("listing works without an engine")
	}
	for i := 0; i < 3; i++ {
		p := filepath.Join(dir, "store", string(rune('a'+i)))
		os.MkdirAll(p, 0o700)
		if _, err := s.AddBackend(ctx, &pb.AddBackendRequest{Name: "disk", Type: "local", Params: map[string]string{"path": p}}); err == nil {
			t.Fatal("unknown option accepted")
		}
		if _, err := s.AddBackend(ctx, &pb.AddBackendRequest{Name: "disk", Type: "local", Root: "rel"}); err == nil {
			t.Fatal("relative local folder accepted")
		}
		if _, err := s.AddBackend(ctx, &pb.AddBackendRequest{Name: "disk", Type: "local", Root: p}); err != nil {
			t.Fatal(err)
		}
		waitReload(t, s)
	}
	// The same folder (or one inside it) cannot become a second storage.
	same := filepath.Join(dir, "store", "a", "inner")
	os.MkdirAll(same, 0o700)
	if _, err := s.AddBackend(ctx, &pb.AddBackendRequest{Name: "again", Type: "local", Root: same}); status.Code(err) != codes.AlreadyExists {
		t.Fatalf("storage in the same folder: %v", err)
	}
	st, _ = s.GetState(ctx, &pb.Empty{})
	if !st.Ready {
		t.Fatalf("not ready with k+m storages: %s", st.Problem)
	}
	rep, _ := s.Status(ctx, &pb.Empty{})
	if _, err := s.RenameBackend(ctx, &pb.RenameBackendRequest{Id: rep.Backends[0].Id, Name: " Disk A "}); err != nil {
		t.Fatal(err)
	}
	if rep, _ = s.Status(ctx, &pb.Empty{}); rep.Backends[0].Name != "Disk A" || rep.Backends[0].Preparing {
		t.Fatalf("after rename: %+v", rep.Backends[0])
	}
	if _, err := s.RenameBackend(ctx, &pb.RenameBackendRequest{Id: rep.Backends[0].Id, Name: " "}); err == nil {
		t.Fatal("empty name accepted")
	}

	local := filepath.Join(dir, "report.txt")
	os.WriteFile(local, []byte("hello"), 0o600)
	if r, err := s.Upload(ctx, &pb.UploadRequest{LocalPaths: []string{local}, RemoteDir: "/docs"}); err != nil || r.Files != 1 {
		t.Fatalf("upload: %v %v", r, err)
	}
	for i := 0; i < 3; i++ { // every storage holds its own part
		p := filepath.Join(dir, "store", string(rune('a'+i)))
		if n := countFiles(p); n == 0 {
			t.Fatalf("storage %s is empty", p)
		}
	}
	found, err := s.Search(ctx, &pb.SearchRequest{Query: "REPORT"})
	if err != nil || len(found.Entries) != 1 || found.Entries[0].Path != "/docs/report.txt" {
		t.Fatalf("search: %v %v", found, err)
	}
	if l, _ := s.Locks(ctx, &pb.PathsRequest{Paths: []string{"/docs/report.txt"}}); len(l.Locks) != 0 {
		t.Fatal("unlocked file reported as locked")
	}
	e, _ := s.Engine()
	lk, err := e.Lock(ctx, "/docs/report.txt")
	if err != nil {
		t.Fatal(err)
	}
	l, _ := s.Locks(ctx, &pb.PathsRequest{Paths: []string{"/docs/report.txt", "/docs"}})
	if len(l.Locks) != 1 || !l.Locks[0].Mine || l.Locks[0].Path != "/docs/report.txt" {
		t.Fatalf("locks: %v", l)
	}
	lk.Release(ctx)

	// Password safe: lists carry no secrets, GetSecret opens one entry.
	g, err := s.PutSecretGroup(ctx, &pb.SecretGroup{Name: "Work"})
	if err != nil {
		t.Fatal(err)
	}
	put, err := s.PutSecret(ctx, &pb.SecretEntry{Kind: pb.SecretKind_SECRET_PASSWORD, Title: "Mail", GroupId: g.Id, Password: "pw1", Notes: "n"})
	if err != nil || put.Password != "" || put.Opened {
		t.Fatalf("put secret: %v %v", put, err)
	}
	if _, err := s.PutSecret(ctx, &pb.SecretEntry{Kind: pb.SecretKind_SECRET_SSH, Title: "k", PrivateKey: "x"}); status.Code(err) != codes.InvalidArgument {
		t.Fatalf("bad key: %v", err)
	}
	if dk, err := s.DeriveKey(ctx, &pb.DeriveKeyRequest{Kind: pb.SecretKind_SECRET_WEB3, PrivateKey: "0000000000000000000000000000000000000000000000000000000000000001"}); err != nil || dk.Address != "0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf" {
		t.Fatalf("derive: %v %v", dk, err)
	}

	if _, err := s.SetRedundancy(ctx, &pb.SetRedundancyRequest{DataShards: 3, ParityShards: 1}); err == nil {
		t.Fatal("k+m=4 accepted with 3 storages")
	}
	st, _ = s.LockVault(ctx, &pb.Empty{})
	if st.Unlocked {
		t.Fatal("still unlocked")
	}
	st, err = s.Unlock(ctx, &pb.UnlockRequest{Password: "pw", DeviceName: "laptop"})
	if err != nil || !st.Ready {
		t.Fatalf("unlock: %v %v", st, err)
	}
	if ls, err := s.List(ctx, &pb.PathRequest{Path: "/docs"}); err != nil || len(ls.Entries) != 1 {
		t.Fatalf("after unlock: %v %v", ls, err)
	}
	list, err := s.ListSecrets(ctx, &pb.Empty{})
	if err != nil || len(list.Entries) != 1 || len(list.Groups) != 1 || list.Entries[0].Password != "" {
		t.Fatalf("secrets after unlock: %v %v", list, err)
	}
	got, err := s.GetSecret(ctx, &pb.IdRequest{Id: put.Id})
	if err != nil || !got.Opened || got.Password != "pw1" || got.GroupId != g.Id {
		t.Fatalf("get secret: %v %v", got, err)
	}
}

// waitReload waits for the background reopen after a vault change.
func waitReload(t *testing.T, s *Service) {
	t.Helper()
	time.Sleep(50 * time.Millisecond) // let the reload goroutine take the lock
	s.reloadMu.Lock()
	s.reloadMu.Unlock()
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.v == nil {
		t.Fatal("vault closed by a reload")
	}
}

func countFiles(dir string) int {
	n := 0
	filepath.WalkDir(dir, func(_ string, d os.DirEntry, err error) error {
		if err == nil && !d.IsDir() {
			n++
		}
		return nil
	})
	return n
}
