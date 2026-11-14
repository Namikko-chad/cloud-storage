package backend

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"sync"

	"github.com/rclone/rclone/fs"
	"github.com/rclone/rclone/fs/config"
	"github.com/rclone/rclone/fs/config/configmap"
	"github.com/rclone/rclone/lib/oauthutil"

	"cloudsync/core/vault"
)

var oauthMu sync.Mutex // rclone keeps one sign-in server and URL hook

// Authorize runs the browser sign-in of an OAuth storage type (Google
// Drive, OneDrive, Dropbox, ...) and returns the token to put into the
// storage's "token" parameter. openURL gets the address the user must open;
// the provider redirects back to http://127.0.0.1:53682 served here, so the
// browser must run on this device. params may carry client_id and
// client_secret of an own OAuth app. Cancel ctx to give up.
func Authorize(ctx context.Context, typ string, params map[string]string, openURL func(string) error) (string, error) {
	ri, err := fs.Find(typ)
	if err != nil {
		return "", err
	}
	if ri.Config == nil {
		return "", errors.New("storage type " + typ + " has no browser sign-in")
	}
	oauthMu.Lock()
	defer oauthMu.Unlock()

	ctx = fs.ConfigOAuthOnly(ctx)
	ctx, ci := fs.AddConfig(ctx)
	ci.AutoConfirm = true // take defaults instead of asking on a terminal

	in := configmap.Simple{config.ConfigAuthorize: "true"}
	for k, v := range params {
		if v != "" {
			in[k] = v
		}
	}
	name := "cs-authorize"
	m := fs.ConfigMap(ri.Prefix, ri.Options, name, in)
	out := configmap.Simple{}
	m.ClearSetters()
	m.AddSetter(out)
	m.AddGetter(out, configmap.PriorityNormal)

	prev := oauthutil.OpenURL
	oauthutil.OpenURL = openURL
	defer func() { oauthutil.OpenURL = prev }()

	if err := config.PostConfig(ctx, name, m, ri); err != nil {
		return "", err
	}
	if out["token"] == "" {
		return "", errors.New("sign-in finished without a token")
	}
	return out["token"], nil
}

// HasSignIn reports whether storages of type typ get their token from a
// browser sign-in (Authorize).
func HasSignIn(typ string) bool {
	ri, err := fs.Find(typ)
	if err != nil || ri.Config == nil {
		return false
	}
	return ri.Options.Get("token") != nil
}

// Reauthorize signs in to the account of an existing storage b again (its
// token was revoked or expired) and returns the new token and the account
// it belongs to. Options of b (an own OAuth app, region, ...) are reused.
// It refuses a different account than the one b was added with: the
// storage's data is there, another account would look empty.
func Reauthorize(ctx context.Context, b vault.Backend, openURL func(string) error) (token, account string, err error) {
	if !HasSignIn(b.Type) {
		return "", "", errors.New("storage type " + b.Type + " has no browser sign-in")
	}
	params := map[string]string{}
	for k, v := range b.Params {
		if k != "token" {
			params[k] = v
		}
	}
	if token, err = Authorize(ctx, b.Type, params, openURL); err != nil {
		return "", "", err
	}
	with := map[string]string{}
	for k, v := range params {
		with[k] = v
	}
	with["token"] = token
	account, _ = WhoAmI(ctx, b.Type, with)
	if old := AccountOf(b); old != "" && account != "" && !strings.EqualFold(old, account) {
		return "", "", fmt.Errorf("signed in as %s, but this storage belongs to %s", account, old)
	}
	return token, account, nil
}

// Reconnect renews the token of storage id in v: a browser sign-in to the
// same account (Reauthorize), a check that the storage answers with the new
// token, then the vault update. ID, folder and data stay as they are.
func Reconnect(ctx context.Context, v *vault.Vault, id string, openURL func(string) error) (account string, err error) {
	b, ok := v.Config().Backend(id)
	if !ok {
		return "", fmt.Errorf("no storage %s", id)
	}
	token, account, err := Reauthorize(ctx, b, openURL)
	if err != nil {
		return "", err
	}
	nb := b
	nb.Params = map[string]string{}
	for k, val := range b.Params {
		nb.Params[k] = val
	}
	nb.Params["token"] = token
	st, err := OpenRclone(ctx, v.Config().VaultID, SharePacing(nb, v.Config().Backends), nil)
	if err != nil {
		return "", err
	}
	if _, err := st.ListDirs(ctx, "j"); err != nil {
		return "", fmt.Errorf("storage still not reachable: %w", err)
	}
	err = v.Update(func(c *vault.Config) error {
		for i := range c.Backends {
			if c.Backends[i].ID == id {
				if c.Backends[i].Params == nil {
					c.Backends[i].Params = map[string]string{}
				}
				c.Backends[i].Params["token"] = token
				if c.Backends[i].Account == "" {
					c.Backends[i].Account = account
				}
				return nil
			}
		}
		return fmt.Errorf("no storage %s", id)
	})
	if err != nil {
		return "", err
	}
	if account == "" {
		account = AccountOf(b)
	}
	return account, nil
}
