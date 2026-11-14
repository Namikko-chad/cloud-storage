package secrets

import (
	"crypto/hmac"
	"crypto/sha1"
	"crypto/sha256"
	"crypto/sha512"
	"encoding/base32"
	"encoding/binary"
	"hash"
	"net/url"
	"regexp"
	"strconv"
	"strings"
	"time"
)

// TOTP is the generator of one-time codes of a two-factor login
// (RFC 6238). It is secret: it lives in Data only.
type TOTP struct {
	Secret    string `json:"secret"`              // base32, upper case, no padding
	Algorithm string `json:"algorithm,omitempty"` // SHA1 (default), SHA256, SHA512
	Digits    int    `json:"digits,omitempty"`    // 6 (default) .. 8
	Period    int    `json:"period,omitempty"`    // seconds, 30 (default)
}

// TOTPInfo is what an otpauth:// URI says besides the generator.
type TOTPInfo struct {
	Issuer, Account string
}

// Limits on recovery codes: a code is short, and a site gives a few.
const (
	maxRecoveryCodes = 100
	maxRecoveryCode  = 128
)

var b32 = base32.StdEncoding.WithPadding(base32.NoPadding)

// ParseTOTP reads a TOTP secret: a base32 key (spaces, dashes and
// padding are ignored) or an otpauth://totp/ URI, whose parameters then
// replace those of t. Missing parameters get the defaults.
func ParseTOTP(input string, t TOTP) (TOTP, TOTPInfo, error) {
	s := strings.TrimSpace(input)
	var info TOTPInfo
	if s == "" {
		return t, info, invalid("the TOTP secret is empty")
	}
	if strings.HasPrefix(strings.ToLower(s), "otpauth:") {
		u, err := url.Parse(s)
		if err != nil {
			return t, info, invalid("not an otpauth:// URI")
		}
		if !strings.EqualFold(u.Host, "totp") {
			return t, info, invalidf("only TOTP is supported, not %q", u.Host)
		}
		label := strings.TrimPrefix(u.Path, "/")
		if i := strings.IndexByte(label, ':'); i >= 0 {
			info.Issuer, info.Account = strings.TrimSpace(label[:i]), strings.TrimSpace(label[i+1:])
		} else {
			info.Account = strings.TrimSpace(label)
		}
		q := u.Query()
		if v := strings.TrimSpace(q.Get("issuer")); v != "" {
			info.Issuer = v
		}
		s = q.Get("secret")
		if v := q.Get("algorithm"); v != "" {
			t.Algorithm = v
		}
		for name, p := range map[string]*int{"digits": &t.Digits, "period": &t.Period} {
			if v := q.Get(name); v != "" {
				n, err := strconv.Atoi(v)
				if err != nil {
					return t, info, invalidf("bad %s in the URI", name)
				}
				*p = n
			}
		}
	}
	key := strings.ToUpper(strings.NewReplacer(" ", "", "-", "", "=", "", "\t", "", "\n", "", "\r", "").Replace(s))
	raw, err := b32.DecodeString(key)
	if err != nil || len(raw) == 0 {
		return t, info, invalid("the TOTP secret is not base32 (letters A–Z and digits 2–7)")
	}
	wipe(raw)
	t.Secret = key
	t.Algorithm = strings.ToUpper(strings.ReplaceAll(strings.TrimSpace(t.Algorithm), "-", ""))
	switch t.Algorithm {
	case "":
		t.Algorithm = "SHA1"
	case "SHA1", "SHA256", "SHA512":
	default:
		return t, info, invalidf("unknown TOTP algorithm %q", t.Algorithm)
	}
	if t.Digits == 0 {
		t.Digits = 6
	}
	if t.Digits < 6 || t.Digits > 8 {
		return t, info, invalid("a TOTP code has 6 to 8 digits")
	}
	if t.Period == 0 {
		t.Period = 30
	}
	if t.Period < 10 || t.Period > 300 {
		return t, info, invalid("a TOTP period is 10 to 300 seconds")
	}
	return t, info, nil
}

// Code is the one-time code at time now and the moment it expires.
// t must come from ParseTOTP.
func (t TOTP) Code(now time.Time) (string, time.Time) {
	period := int64(t.Period)
	step := now.Unix() / period
	return t.codeAt(uint64(step)), time.Unix((step+1)*period, 0)
}

func (t TOTP) codeAt(counter uint64) string {
	key, err := b32.DecodeString(t.Secret)
	if err != nil {
		return ""
	}
	defer wipe(key)
	var newHash func() hash.Hash
	switch t.Algorithm {
	case "SHA256":
		newHash = sha256.New
	case "SHA512":
		newHash = sha512.New
	default:
		newHash = sha1.New
	}
	m := hmac.New(newHash, key)
	var msg [8]byte
	binary.BigEndian.PutUint64(msg[:], counter)
	m.Write(msg[:])
	sum := m.Sum(nil)
	off := sum[len(sum)-1] & 0x0f
	v := binary.BigEndian.Uint32(sum[off:off+4]) & 0x7fffffff
	mod := uint32(1)
	for range t.Digits {
		mod *= 10
	}
	s := strconv.FormatUint(uint64(v%mod), 10)
	return strings.Repeat("0", t.Digits-len(s)) + s
}

var (
	// Separators between codes on one line: tabs, commas, semicolons,
	// bars and runs of two or more spaces. A single space stays: Google
	// writes a code as "1234 5678".
	codeSeparators = regexp.MustCompile(`[\t,;|]+| {2,}`)
	// A list marker before a code: "1.", "2)", "-", "*", "•".
	codeMarker = regexp.MustCompile(`^(\d{1,3}[.)]\s+|[-*•·]\s*)`)
	// A code: letters and digits, in groups split by a dash or a space.
	codeShape = regexp.MustCompile(`^[\p{L}\p{N}]+([- ][\p{L}\p{N}]+){0,7}$`)
	hasDigit  = regexp.MustCompile(`\p{N}`)
)

// ParseRecoveryCodes picks the recovery codes out of pasted text: a
// site's list, one or several codes a line, numbered or not, with the
// header and the notes of a downloaded file. A line that is not all
// codes (has words, punctuation, an e-mail) is skipped; a code has a
// digit. If nothing looks like a code, every non-empty line is one.
// Repeats are dropped; the order is kept.
func ParseRecoveryCodes(text string) []string {
	var codes []string
	seen := map[string]bool{}
	add := func(c string) {
		if c != "" && !seen[c] {
			seen[c] = true
			codes = append(codes, c)
		}
	}
	lines := strings.FieldsFunc(text, func(r rune) bool { return r == '\n' || r == '\r' })
	for _, line := range lines {
		var found []string
		ok := true
		for _, tok := range codeSeparators.Split(strings.TrimSpace(line), -1) {
			tok = strings.TrimSpace(codeMarker.ReplaceAllString(strings.TrimSpace(tok), ""))
			if tok == "" {
				continue
			}
			if !codeShape.MatchString(tok) || !hasDigit.MatchString(tok) {
				ok = false
				break
			}
			found = append(found, tok)
		}
		if ok {
			for _, c := range found {
				add(c)
			}
		}
	}
	if len(codes) == 0 {
		for _, line := range lines {
			add(strings.TrimSpace(line))
		}
	}
	return codes
}

// SameCode tells whether two recovery codes are the same, ignoring case,
// spaces and dashes (a code is often typed back differently).
func SameCode(a, b string) bool {
	norm := strings.NewReplacer(" ", "", "-", "")
	return strings.EqualFold(norm.Replace(a), norm.Replace(b))
}
