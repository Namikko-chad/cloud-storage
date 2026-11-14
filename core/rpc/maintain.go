package rpc

import (
	"context"
	"fmt"
	"strings"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"cloudsync/core/backend"
	"cloudsync/core/engine"
	"cloudsync/core/erasure"
	"cloudsync/core/eventlog"
	"cloudsync/core/index"
	"cloudsync/core/rpc/pb"
	"cloudsync/core/vault"
)

func (s *Service) Repair(ctx context.Context, r *pb.RepairRequest) (*pb.RepairReply, error) {
	e, err := s.engine()
	if err != nil {
		return nil, err
	}
	// It reads every shard of every file: on a slow link it takes minutes,
	// and the summary below is only written at the end.
	s.Log.Add(eventlog.Info, "repair", "", "started: reading every shard of every file")
	start := time.Now()
	rep, err := e.Repair(ctx, engine.RepairOptions{Rebalance: r.Rebalance})
	out := &pb.RepairReply{
		Blobs: int32(rep.Blobs), Repaired: int32(rep.Repaired), Failed: int32(rep.Failed),
		JournalCopies: int32(rep.Journal), Reencoded: int32(rep.Reencoded), Moved: int32(rep.Moved),
		Damaged: rep.Damaged, FromLocal: int32(rep.FromLocal),
	}
	if rep.FromLocal > 0 {
		s.Log.Addf(eventlog.Info, "repair", "", "%d blobs rebuilt from the copy on this device", rep.FromLocal)
	}
	if rep.Reencoded > 0 || rep.Repaired > 0 || rep.Moved > 0 {
		s.changed()
	}
	summary := fmt.Sprintf("%d blobs checked, %d repaired, %d re-encoded, %d moved, %d failed, %d journal copies in %s",
		rep.Blobs, rep.Repaired, rep.Reencoded, rep.Moved, rep.Failed, rep.Journal, time.Since(start).Round(time.Second))
	if err != nil {
		for _, e := range unjoin(err) {
			s.Log.Add(eventlog.Error, "repair", "", e.Error())
		}
		s.Log.Add(eventlog.Warn, "repair", "", "finished with errors: "+summary)
	} else {
		s.Log.Add(eventlog.Info, "repair", "", "done: "+summary)
	}
	if err != nil && ctx.Err() == nil && rep.Blobs > 0 {
		// It ran through: the reply says what failed (Failed, Damaged),
		// the details are in the log. An error would drop the reply.
		return out, nil
	}
	return out, toStatus(err)
}

func (s *Service) GC(ctx context.Context, r *pb.GCRequest) (*pb.GCReply, error) {
	e, err := s.engine()
	if err != nil {
		return nil, err
	}
	grace := engine.DefaultGrace
	if r.GraceSeconds > 0 {
		grace = time.Duration(r.GraceSeconds) * time.Second
	}
	rep, err := e.GC(ctx, grace)
	summary := fmt.Sprintf("%d objects, %d unused, %d deleted", rep.Objects, rep.Unused, rep.Deleted)
	if len(rep.Skipped) > 0 {
		summary += ", skipped: " + strings.Join(rep.Skipped, ", ")
	}
	if err != nil {
		for _, e := range unjoin(err) {
			s.Log.Add(eventlog.Error, "gc", "", e.Error())
		}
		s.Log.Add(eventlog.Warn, "gc", "", "finished with errors: "+summary)
	} else {
		s.Log.Add(eventlog.Info, "gc", "", "done: "+summary)
	}
	return &pb.GCReply{
		Objects: int32(rep.Objects), Unused: int32(rep.Unused), Deleted: int32(rep.Deleted), Skipped: rep.Skipped,
	}, toStatus(err)
}

// unjoin splits an errors.Join result so each failure is its own event.
func unjoin(err error) []error {
	if j, ok := err.(interface{ Unwrap() []error }); ok {
		var out []error
		for _, e := range j.Unwrap() {
			out = append(out, unjoin(e)...)
		}
		return out
	}
	return []error{err}
}

func (s *Service) SetRedundancy(ctx context.Context, r *pb.SetRedundancyRequest) (*pb.Empty, error) {
	k, m := int(r.DataShards), int(r.ParityShards)
	e, err := s.engine()
	if err == nil {
		err = e.SetRedundancy(k, m)
	} else {
		// Not ready yet (setting up): change the vault directly.
		s.mu.Lock()
		v := s.v
		s.mu.Unlock()
		if v == nil {
			return nil, err
		}
		if _, err = erasure.New(k, m); err == nil {
			err = v.Update(func(c *vault.Config) error {
				c.DataShards, c.ParityShards = k, m
				return nil
			})
		}
	}
	if err != nil {
		return nil, status.Error(codes.InvalidArgument, err.Error())
	}
	go s.reload(context.Background())
	return &pb.Empty{}, nil
}

func (s *Service) RemoveBackend(ctx context.Context, r *pb.RemoveBackendRequest) (*pb.Empty, error) {
	e, err := s.engine()
	if err != nil {
		return nil, err
	}
	name := r.Id
	if b, ok := e.Config().Backend(r.Id); ok {
		name = b.Name
	}
	if err := e.RemoveBackend(r.Id, r.Force); err != nil {
		return nil, status.Error(codes.FailedPrecondition, err.Error())
	}
	if r.Force {
		s.Log.Addf(eventlog.Warn, "storage", r.Id, "%s: removed although it held shards; run repair to rebuild them elsewhere", name)
	} else {
		s.Log.Addf(eventlog.Info, "storage", r.Id, "%s: removed", name)
	}
	go s.reload(context.Background())
	return &pb.Empty{}, nil
}

func (s *Service) Authorize(r *pb.AuthorizeRequest, stream pb.CloudSync_AuthorizeServer) error {
	open := func(url string) error {
		return stream.Send(&pb.AuthorizeReply{Url: url})
	}
	token, err := backend.Authorize(stream.Context(), r.Type, r.Params, open)
	if err != nil {
		return status.Error(codes.Aborted, err.Error())
	}
	reply := &pb.AuthorizeReply{Token: token}
	reply.Account, _ = backend.WhoAmI(stream.Context(), r.Type, map[string]string{"token": token})
	return stream.Send(reply)
}

func (s *Service) Reconnect(r *pb.IdRequest, stream pb.CloudSync_ReconnectServer) error {
	s.mu.Lock()
	v := s.v
	s.mu.Unlock()
	if v == nil {
		return status.Error(codes.FailedPrecondition, "vault is locked")
	}
	b, ok := v.Config().Backend(r.Id)
	if !ok {
		return status.Errorf(codes.NotFound, "no storage %s", r.Id)
	}
	open := func(url string) error {
		return stream.Send(&pb.AuthorizeReply{Url: url})
	}
	account, err := backend.Reconnect(stream.Context(), v, r.Id, open)
	if err != nil {
		return status.Error(codes.Aborted, err.Error())
	}
	s.Log.Addf(eventlog.Info, "storage", b.ID, "%s: signed in again (%s)", b.Name, firstNonEmpty(account, b.Type))
	go s.reload(context.Background())
	return stream.Send(&pb.AuthorizeReply{Account: account})
}

func (s *Service) Locks(ctx context.Context, r *pb.PathsRequest) (*pb.LocksReply, error) {
	e, err := s.engine()
	if err != nil {
		return nil, err
	}
	out := &pb.LocksReply{}
	for p, h := range e.Locks(ctx, r.Paths) {
		out.Locks = append(out.Locks, &pb.LockInfo{
			Path: p, Locked: true, DeviceId: h.Device, DeviceName: h.DeviceName,
			SinceUnix: h.Created.Unix(), Mine: h.Device == e.DeviceID(),
		})
	}
	return out, nil
}

func (s *Service) Search(_ context.Context, r *pb.SearchRequest) (*pb.ListReply, error) {
	e, err := s.engine()
	if err != nil {
		return nil, err
	}
	q := strings.ToLower(strings.TrimSpace(r.Query))
	limit := int(r.Limit)
	if limit <= 0 {
		limit = 200
	}
	out := &pb.ListReply{}
	if q == "" {
		return out, nil
	}
	e.Index().Walk(func(en index.Entry) {
		if len(out.Entries) < limit && strings.Contains(strings.ToLower(en.Name()), q) {
			out.Entries = append(out.Entries, s.entry(e, en))
		}
	})
	return out, nil
}
