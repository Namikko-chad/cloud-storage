package engine

import (
	"bytes"
	"context"
	"errors"
	"io/fs"
	"os"
	"path/filepath"
	"reflect"
	"testing"
	"time"

	"cloudsync/core/secrets"
)

func TestSafeTOTP(t *testing.T) {
	ctx := context.Background()
	w := newWorld(t)
	a, b := w.device("laptop"), w.device("phone")

	en, err := a.PutSecret(ctx, "", "", secrets.Meta{Kind: secrets.KindTOTP},
		secrets.Data{
			TOTP:          &secrets.TOTP{Secret: "otpauth://totp/GitHub:octo?secret=JBSWY3DPEHPK3PXP"},
			RecoveryCodes: []string{"c0de1-aaaa1\nc0de2-bbbb2\nc0de3-cccc3"},
		})
	if err != nil || en.Title != "GitHub" || en.RecoveryLeft != 3 {
		t.Fatalf("%+v %v", en, err)
	}
	b.Sync(ctx)

	now := time.Unix(1_800_000_000, 0)
	ca, cb := a.TOTPCodes(now), b.TOTPCodes(now)
	if len(ca) != 1 || !reflect.DeepEqual(ca, cb) || ca[0].ID != en.ID || len(ca[0].Code) != 6 || ca[0].Period != 30 ||
		ca[0].Next == "" || !ca[0].Expires.After(now) {
		t.Fatalf("codes %+v / %+v", ca, cb)
	}

	if _, err := b.UseRecoveryCode(ctx, en.ID, "C0DE2BBBB2"); err != nil {
		t.Fatal(err)
	}
	if _, err := b.UseRecoveryCode(ctx, en.ID, "c0de2-bbbb2"); !errors.Is(err, ErrNotFound) {
		t.Fatalf("used twice: %v", err)
	}
	a.Sync(ctx)
	got, err := a.OpenSecret(en.ID)
	if err != nil || got.RecoveryLeft != 2 || !reflect.DeepEqual(got.Data.RecoveryCodes, []string{"c0de1-aaaa1", "c0de3-cccc3"}) ||
		got.Data.TOTP.Secret != "JBSWY3DPEHPK3PXP" {
		t.Fatalf("after use: %+v %+v %v", got.Meta, got.Data, err)
	}
	if l := a.Safe(); len(l.Entries) != 1 || l.Entries[0].RecoveryLeft != 2 {
		t.Fatalf("list %+v", l)
	}

	pw, _ := a.PutSecret(ctx, "", "", secrets.Meta{Kind: secrets.KindPassword, Title: "p"}, secrets.Data{Password: "x"})
	if _, err := a.UseRecoveryCode(ctx, pw.ID, "x"); !errors.Is(err, secrets.ErrInvalid) {
		t.Fatalf("password entry: %v", err)
	}

	for _, dir := range []string{a.opt.DataDir, b.opt.DataDir} {
		filepath.WalkDir(dir, func(p string, d fs.DirEntry, err error) error {
			if err != nil || d.IsDir() {
				return err
			}
			data, _ := os.ReadFile(p)
			for _, s := range []string{"JBSWY3DP", "c0de1", "bbbb2"} {
				if bytes.Contains(data, []byte(s)) {
					t.Errorf("%s holds %q in the clear", p, s)
				}
			}
			return nil
		})
	}
}
