package backend

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"path/filepath"
	"strings"
	"time"

	"cloudsync/core/vault"
)

// AccountFromParams returns who a storage signs in as when its options say
// it (Mega e-mail, SFTP user@host, ...); "" when they do not (OAuth types:
// see WhoAmI).
func AccountFromParams(typ string, params map[string]string) string {
	p := func(k string) string { return strings.TrimSpace(params[k]) }
	host := func(raw string) string {
		if u, err := url.Parse(raw); err == nil && u.Host != "" {
			return u.Host
		}
		return raw
	}
	join := func(user, at string) string {
		switch {
		case user == "":
			return at
		case at == "":
			return user
		}
		return user + "@" + at
	}
	switch typ {
	case "mega":
		return p("user")
	case "sftp":
		return join(p("user"), p("host"))
	case "webdav":
		return join(p("user"), host(p("url")))
	case "s3":
		return join(p("access_key_id"), firstNonEmpty(host(p("endpoint")), p("provider")))
	case "b2":
		return p("account")
	}
	return ""
}

func firstNonEmpty(s ...string) string {
	for _, x := range s {
		if x != "" {
			return x
		}
	}
	return ""
}

// AccountOf returns the account recorded for b, or the one its options name.
func AccountOf(b vault.Backend) string {
	if b.Account != "" {
		return b.Account
	}
	return AccountFromParams(b.Type, b.Params)
}

// Location identifies where a storage keeps its data: two storages with
// the same location are one account (or one folder), so they add no
// redundancy and would see each other's objects. "" means unknown.
func Location(b vault.Backend) string {
	if b.Type == "local" {
		if b.Root == "" {
			return ""
		}
		return "local|" + filepath.Clean(b.Root)
	}
	acc := strings.ToLower(AccountOf(b))
	if acc == "" {
		return ""
	}
	return b.Type + "|" + acc
}

// SameLocation reports whether a and b store data in the same place: the
// same account of one provider, or local folders that are equal or nested.
func SameLocation(a, b vault.Backend) bool {
	la, lb := Location(a), Location(b)
	if la == "" || lb == "" {
		return false
	}
	if a.Type == "local" && b.Type == "local" {
		ra, rb := filepath.Clean(a.Root), filepath.Clean(b.Root)
		return ra == rb || strings.HasPrefix(ra, rb+string(filepath.Separator)) || strings.HasPrefix(rb, ra+string(filepath.Separator))
	}
	return la == lb
}

// WhoAmI asks an OAuth provider which account the token in params belongs
// to (an e-mail or login). It fails for types it does not know and when the
// access token has expired (rclone refreshes it on use; try again later).
func WhoAmI(ctx context.Context, typ string, params map[string]string) (string, error) {
	var tok struct {
		AccessToken string `json:"access_token"`
	}
	if err := json.Unmarshal([]byte(params["token"]), &tok); err != nil || tok.AccessToken == "" {
		return "", errors.New("no access token")
	}
	ctx, cancel := context.WithTimeout(ctx, 15*time.Second)
	defer cancel()
	bearer := "Bearer " + tok.AccessToken
	var out map[string]any
	var err error
	switch typ {
	case "drive":
		out, err = getJSON(ctx, http.MethodGet, "https://www.googleapis.com/drive/v3/about?fields=user", bearer)
		return pick(out, err, "user.emailAddress", "user.displayName")
	case "onedrive":
		out, err = getJSON(ctx, http.MethodGet, "https://graph.microsoft.com/v1.0/me/drive?$select=owner", bearer)
		return pick(out, err, "owner.user.email", "owner.user.displayName")
	case "dropbox":
		out, err = getJSON(ctx, http.MethodPost, "https://api.dropboxapi.com/2/users/get_current_account", bearer)
		return pick(out, err, "email", "name.display_name")
	case "box":
		out, err = getJSON(ctx, http.MethodGet, "https://api.box.com/2.0/users/me", bearer)
		return pick(out, err, "login", "name")
	case "pcloud":
		host := params["hostname"]
		if host == "" {
			host = "api.pcloud.com"
		}
		out, err = getJSON(ctx, http.MethodGet, "https://"+host+"/userinfo", bearer)
		return pick(out, err, "email")
	case "yandex":
		out, err = getJSON(ctx, http.MethodGet, "https://cloud-api.yandex.net/v1/disk/", "OAuth "+tok.AccessToken)
		return pick(out, err, "user.login", "user.display_name")
	}
	return "", fmt.Errorf("%s: account lookup not supported", typ)
}

func getJSON(ctx context.Context, method, u, auth string) (map[string]any, error) {
	var body io.Reader
	if method == http.MethodPost {
		body = strings.NewReader("null")
	}
	req, err := http.NewRequestWithContext(ctx, method, u, body)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", auth)
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	data, _ := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	if resp.StatusCode/100 != 2 {
		return nil, fmt.Errorf("account lookup: HTTP %d", resp.StatusCode)
	}
	var out map[string]any
	if err := json.Unmarshal(data, &out); err != nil {
		return nil, err
	}
	return out, nil
}

// pick returns the first non-empty string at one of the dotted paths.
func pick(m map[string]any, err error, paths ...string) (string, error) {
	if err != nil {
		return "", err
	}
	for _, p := range paths {
		var cur any = m
		for _, k := range strings.Split(p, ".") {
			mm, ok := cur.(map[string]any)
			if !ok {
				cur = nil
				break
			}
			cur = mm[k]
		}
		if s, ok := cur.(string); ok && s != "" {
			return s, nil
		}
	}
	return "", errors.New("account lookup: no account in reply")
}

// CompleteParams fills options a storage type needs besides the sign-in
// token, which rclone's interactive config would otherwise ask for. OneDrive
// needs drive_id and drive_type: they are taken from the account's default
// drive. Params are returned unchanged for other types or when already set.
func CompleteParams(ctx context.Context, typ string, params map[string]string) (map[string]string, error) {
	if typ != "onedrive" || params["token"] == "" || (params["drive_id"] != "" && params["drive_type"] != "") {
		return params, nil
	}
	var tok struct {
		AccessToken string `json:"access_token"`
	}
	if err := json.Unmarshal([]byte(params["token"]), &tok); err != nil || tok.AccessToken == "" {
		return nil, errors.New("onedrive: no access token, sign in again")
	}
	graph := map[string]string{
		"":       "https://graph.microsoft.com",
		"global": "https://graph.microsoft.com",
		"us":     "https://graph.microsoft.us",
		"de":     "https://graph.microsoft.de",
		"cn":     "https://microsoftgraph.chinacloudapi.cn",
	}[params["region"]]
	if graph == "" {
		return nil, fmt.Errorf("onedrive: unknown region %q", params["region"])
	}
	ctx, cancel := context.WithTimeout(ctx, 15*time.Second)
	defer cancel()
	out, err := getJSON(ctx, http.MethodGet, graph+"/v1.0/me/drive?$select=id,driveType", "Bearer "+tok.AccessToken)
	if err != nil {
		return nil, fmt.Errorf("onedrive: find the drive: %w", err)
	}
	id, _ := out["id"].(string)
	dt, _ := out["driveType"].(string)
	if id == "" || dt == "" {
		return nil, errors.New("onedrive: the account has no drive")
	}
	res := make(map[string]string, len(params)+2)
	for k, v := range params {
		res[k] = v
	}
	res["drive_id"], res["drive_type"] = id, dt
	return res, nil
}
