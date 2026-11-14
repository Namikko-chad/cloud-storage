package secrets

import (
	"encoding/base32"
	"errors"
	"reflect"
	"testing"
	"time"
)

// RFC 6238, appendix B.
func TestTOTPVectors(t *testing.T) {
	enc := func(s string) string { return base32.StdEncoding.EncodeToString([]byte(s)) }
	keys := map[string]string{
		"SHA1":   enc("12345678901234567890"),
		"SHA256": enc("12345678901234567890123456789012"),
		"SHA512": enc("1234567890123456789012345678901234567890123456789012345678901234"),
	}
	for _, v := range []struct {
		at   int64
		algo string
		code string
	}{
		{59, "SHA1", "94287082"}, {59, "SHA256", "46119246"}, {59, "SHA512", "90693936"},
		{1111111109, "SHA1", "07081804"}, {1111111111, "SHA256", "67062674"},
		{1234567890, "SHA512", "93441116"}, {20000000000, "SHA1", "65353130"},
	} {
		g, _, err := ParseTOTP(keys[v.algo], TOTP{Algorithm: v.algo, Digits: 8})
		if err != nil {
			t.Fatal(err)
		}
		code, exp := g.Code(time.Unix(v.at, 0))
		if code != v.code || exp.Unix()%30 != 0 || exp.Unix() <= v.at || exp.Unix()-v.at > 30 {
			t.Fatalf("%s at %d: %s until %d, want %s", v.algo, v.at, code, exp.Unix(), v.code)
		}
	}
}

func TestParseTOTP(t *testing.T) {
	g, info, err := ParseTOTP("otpauth://totp/ACME%20Co:john@example.com?secret=jbsw y3dp-ehpk3pxp&issuer=ACME+Co&period=60&digits=8&algorithm=sha256", TOTP{})
	if err != nil {
		t.Fatal(err)
	}
	if g != (TOTP{Secret: "JBSWY3DPEHPK3PXP", Algorithm: "SHA256", Digits: 8, Period: 60}) ||
		info != (TOTPInfo{Issuer: "ACME Co", Account: "john@example.com"}) {
		t.Fatalf("%+v %+v", g, info)
	}
	g, _, err = ParseTOTP(" jbsw y3dp ehpk 3pxp== ", TOTP{})
	if err != nil || g != (TOTP{Secret: "JBSWY3DPEHPK3PXP", Algorithm: "SHA1", Digits: 6, Period: 30}) {
		t.Fatalf("%+v %v", g, err)
	}
	if again, _, err := ParseTOTP(g.Secret, g); err != nil || again != g {
		t.Fatalf("not idempotent: %+v %v", again, err)
	}
	for _, bad := range []string{"", "not base32 1890", "otpauth://hotp/x?secret=JBSWY3DP", "otpauth://totp/x?secret=JBSWY3DP&digits=12",
		"otpauth://totp/x?secret=JBSWY3DP&algorithm=MD5", "otpauth://totp/x"} {
		if _, _, err := ParseTOTP(bad, TOTP{}); !errors.Is(err, ErrInvalid) {
			t.Fatalf("%q: %v", bad, err)
		}
	}
}

func TestParseRecoveryCodes(t *testing.T) {
	for _, c := range []struct {
		in   string
		want []string
	}{
		// GitHub
		{"a1b2c-3d4e5\n f6a7b-8c9d0 \r\n\na1b2c-3d4e5\n", []string{"a1b2c-3d4e5", "f6a7b-8c9d0"}},
		// Google's downloaded file: two columns, numbered, header and notes.
		{`SAVE YOUR BACKUP CODES
Keep these backup codes somewhere safe but accessible.

1. 4412 4211		6. 1234 5678
2. 9921 0042		7. 8765 4321
(john@example.com)
* You can only use each backup code once.
* These codes were generated on: Nov 13, 2026`, []string{"4412 4211", "1234 5678", "9921 0042", "8765 4321"}},
		// One line, commas; bullets.
		{"111111, 222222; 333333", []string{"111111", "222222", "333333"}},
		{"- XK3P-9QWE\n• 7HHG-21ZZ", []string{"XK3P-9QWE", "7HHG-21ZZ"}},
		// Nothing looks like a code: each line is kept.
		{"alpha-bravo\ncharlie-delta", []string{"alpha-bravo", "charlie-delta"}},
		{"  \n", nil},
	} {
		if got := ParseRecoveryCodes(c.in); !reflect.DeepEqual(got, c.want) {
			t.Errorf("%q:\n got %q\nwant %q", c.in, got, c.want)
		}
	}
	if !SameCode("a1b2c-3d4e5", " A1B2C3D4E5") || SameCode("1234 5678", "1234 5679") {
		t.Fatal("SameCode")
	}
}

func TestPrepareTOTP(t *testing.T) {
	m := Meta{Kind: KindTOTP}
	d := Data{
		TOTP:          &TOTP{Secret: "otpauth://totp/GitHub:octo?secret=JBSWY3DPEHPK3PXP&issuer=GitHub"},
		RecoveryCodes: []string{"1. 1111 2222  2. 3333 4444\nthanks!"},
		Password:      "stray",
	}
	if err := Prepare(&m, &d); err != nil {
		t.Fatal(err)
	}
	if m.Title != "GitHub" || m.Username != "octo" || m.RecoveryLeft != 2 || d.Password != "" ||
		d.TOTP.Secret != "JBSWY3DPEHPK3PXP" || !reflect.DeepEqual(d.RecoveryCodes, []string{"1111 2222", "3333 4444"}) {
		t.Fatalf("%+v %+v", m, d)
	}
	m2, d2 := m, d
	if err := Prepare(&m2, &d2); err != nil || m2 != m || !reflect.DeepEqual(d2, d) {
		t.Fatalf("not idempotent: %+v %+v %v", m2, d2, err)
	}
	if err := Prepare(&Meta{Kind: KindTOTP, Title: "x"}, &Data{}); !errors.Is(err, ErrInvalid) {
		t.Fatal("TOTP without a secret accepted")
	}
	// Other kinds drop TOTP fields.
	pm, pd := Meta{Kind: KindPassword, Title: "p", RecoveryLeft: 3}, Data{TOTP: &TOTP{}, RecoveryCodes: []string{"1"}}
	if err := Prepare(&pm, &pd); err != nil || pd.TOTP != nil || pd.RecoveryCodes != nil || pm.RecoveryLeft != 0 {
		t.Fatalf("%+v %+v %v", pm, pd, err)
	}
}
