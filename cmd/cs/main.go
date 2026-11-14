// Command cs is a command line client for a cloudsync vault. It is meant
// for testing the core against real storages and for scripting.
package main

import (
	"bufio"
	"context"
	"errors"
	"flag"
	"fmt"
	"os"
	"os/signal"
	"path/filepath"
	"runtime"
	"strings"
	"syscall"
	"text/tabwriter"
	"time"

	"golang.org/x/term"

	"cloudsync/core/backend"
	"cloudsync/core/crypto"
	"cloudsync/core/engine"
	"cloudsync/core/index"
	"cloudsync/core/vault"
)

const usage = `cs — cloudsync command line

Vault:
  cs init [-k 2] [-m 1]                  create a vault
  cs passwd                              change the vault password
  cs backend add -name N -type T [-domain D] [-root R] key=value...
                                         -root: folder in the account; for -type local
                                         an absolute path on this machine
  cs backend ls | types
  cs backend disable|enable ID
  cs backend reconnect ID      sign in again (expired or revoked token)
  cs status                              storages, devices, pending changes

Files:
  cs ls [-l] [PATH]
  cs put LOCAL... REMOTE_DIR             upload files or directories
  cs get REMOTE LOCAL                    download a file or directory
  cs cat REMOTE
  cs mkdir PATH | rm [-r] PATH | mv FROM TO
  cs pin PATH | unpin PATH | pins        keep files on this device
  cs lock PATH                           hold the write lock until Ctrl-C
  cs sync

Maintenance:
  cs repair [-rebalance]                 check every shard, rewrite lost ones, re-encode
                                         after a k/m change; -rebalance spreads data
                                         over storages added later
  cs gc [-grace 168h]                    remove data no file uses any more
  cs redundancy -k K -m M                change k/m for new files (then cs repair)

Global flags (before the command):
  -vault FILE   vault file (default: user config dir/cloudsync/vault.cs)
  -data DIR     device state and cache (default: next to the vault)
  -device NAME  this device's name (default: hostname)
The password is read from $CS_PASSWORD or asked for.
Google Drive and other OAuth storages take token='{...}' from "rclone authorize <type>".
`

type app struct {
	vaultPath, dataDir, device string
}

func main() {
	a := app{}
	def := ""
	if d, err := os.UserConfigDir(); err == nil {
		def = filepath.Join(d, "cloudsync", "vault.cs")
	}
	flag.StringVar(&a.vaultPath, "vault", def, "vault file")
	flag.StringVar(&a.dataDir, "data", "", "device data dir")
	flag.StringVar(&a.device, "device", "", "device name")
	flag.Usage = func() { fmt.Fprint(os.Stderr, usage) }
	flag.Parse()
	if flag.NArg() == 0 {
		flag.Usage()
		os.Exit(2)
	}
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	if err := a.run(ctx, flag.Arg(0), flag.Args()[1:]); err != nil {
		fmt.Fprintln(os.Stderr, "cs:", err)
		os.Exit(1)
	}
}

func (a *app) run(ctx context.Context, cmd string, args []string) error {
	switch cmd {
	case "init":
		return a.init(args)
	case "passwd":
		return a.passwd()
	case "backend":
		return a.backend(ctx, args)
	}
	e, err := a.engine(ctx)
	if err != nil {
		return err
	}
	defer e.Close(context.WithoutCancel(ctx))
	switch cmd {
	case "status":
		return status(ctx, e)
	case "ls":
		return ls(e, args)
	case "put":
		return put(ctx, e, args)
	case "get":
		if len(args) != 2 {
			return errors.New("usage: cs get REMOTE LOCAL")
		}
		return e.Download(ctx, args[0], args[1])
	case "cat":
		if len(args) != 1 {
			return errors.New("usage: cs cat REMOTE")
		}
		f, err := e.OpenFile(ctx, args[0])
		if err != nil {
			return err
		}
		_, err = f.WriteTo(os.Stdout)
		return err
	case "mkdir":
		return each(args, func(p string) error { return e.Mkdir(ctx, p) })
	case "rm":
		fl := flag.NewFlagSet("rm", flag.ExitOnError)
		r := fl.Bool("r", false, "recursive")
		fl.Parse(args)
		return each(fl.Args(), func(p string) error { return e.Remove(ctx, p, *r) })
	case "mv":
		if len(args) != 2 {
			return errors.New("usage: cs mv FROM TO")
		}
		return e.Rename(ctx, args[0], args[1])
	case "pin":
		return each(args, func(p string) error { return e.Pin(ctx, p) })
	case "unpin":
		return each(args, e.Unpin)
	case "pins":
		for _, p := range e.Pins() {
			fmt.Println(p)
		}
		return nil
	case "lock":
		if len(args) != 1 {
			return errors.New("usage: cs lock PATH")
		}
		l, err := e.Lock(ctx, args[0])
		if err != nil {
			return err
		}
		fmt.Println("locked", index.Clean(args[0]), "— Ctrl-C to release")
		<-ctx.Done()
		return l.Release(context.WithoutCancel(ctx))
	case "sync":
		return e.Sync(ctx)
	case "repair":
		fl := flag.NewFlagSet("repair", flag.ExitOnError)
		rebalance := fl.Bool("rebalance", false, "also move shards to spread data over storages added later")
		fl.Parse(args)
		rep, err := e.Repair(ctx, engine.RepairOptions{Rebalance: *rebalance})
		fmt.Printf("blobs %d, repaired %d, re-encoded %d, rebalanced %d, failed %d, journal copies %d\n",
			rep.Blobs, rep.Repaired, rep.Reencoded, rep.Moved, rep.Failed, rep.Journal)
		if rep.FromLocal > 0 {
			fmt.Printf("rebuilt from the copy on this device: %d\n", rep.FromLocal)
		}
		if len(rep.Damaged) > 0 {
			fmt.Println("damaged files (parts cannot be read):")
			for _, p := range rep.Damaged {
				fmt.Println("  " + p)
			}
		}
		return err
	case "gc":
		fl := flag.NewFlagSet("gc", flag.ExitOnError)
		grace := fl.Duration("grace", engine.DefaultGrace, "remove objects unused for at least this long")
		fl.Parse(args)
		rep, err := e.GC(ctx, *grace)
		fmt.Printf("objects %d, unused %d, deleted %d\n", rep.Objects, rep.Unused, rep.Deleted)
		if len(rep.Skipped) > 0 {
			fmt.Println("not reachable:", strings.Join(rep.Skipped, ", "))
		}
		return err
	case "redundancy":
		fl := flag.NewFlagSet("redundancy", flag.ExitOnError)
		k := fl.Int("k", e.Config().DataShards, "data shards")
		m := fl.Int("m", e.Config().ParityShards, "parity shards: storages that may be lost")
		fl.Parse(args)
		if err := e.SetRedundancy(*k, *m); err != nil {
			return err
		}
		fmt.Printf("new files use k=%d m=%d; run 'cs repair' to encode existing files again\n", *k, *m)
		return nil
	}
	return fmt.Errorf("unknown command %q (see cs -h)", cmd)
}

func each(args []string, fn func(string) error) error {
	if len(args) == 0 {
		return errors.New("no path given")
	}
	for _, a := range args {
		if err := fn(a); err != nil {
			return err
		}
	}
	return nil
}

func password(confirm bool) ([]byte, error) {
	if p := os.Getenv("CS_PASSWORD"); p != "" {
		return []byte(p), nil
	}
	if !term.IsTerminal(int(os.Stdin.Fd())) {
		line, err := bufio.NewReader(os.Stdin).ReadString('\n')
		return []byte(strings.TrimRight(line, "\r\n")), err
	}
	fmt.Fprint(os.Stderr, "Vault password: ")
	p, err := term.ReadPassword(int(os.Stdin.Fd()))
	fmt.Fprintln(os.Stderr)
	if err != nil || !confirm {
		return p, err
	}
	fmt.Fprint(os.Stderr, "Repeat: ")
	p2, err := term.ReadPassword(int(os.Stdin.Fd()))
	fmt.Fprintln(os.Stderr)
	if err != nil {
		return nil, err
	}
	if string(p) != string(p2) {
		return nil, errors.New("passwords differ")
	}
	return p, nil
}

func (a *app) init(args []string) error {
	fl := flag.NewFlagSet("init", flag.ExitOnError)
	k := fl.Int("k", 2, "data shards")
	m := fl.Int("m", 1, "parity shards (storages that may be lost)")
	fl.Parse(args)
	c, err := vault.New(*k, *m)
	if err != nil {
		return err
	}
	pw, err := password(true)
	if err != nil {
		return err
	}
	if _, err := vault.Create(a.vaultPath, pw, c, vault.DefaultKDF); err != nil {
		return err
	}
	fmt.Printf("vault %s created at %s (k=%d, m=%d: needs at least %d storages)\n", c.VaultID, a.vaultPath, *k, *m, *k+*m)
	return nil
}

func (a *app) open() (*vault.Vault, error) {
	pw, err := password(false)
	if err != nil {
		return nil, err
	}
	return vault.Open(a.vaultPath, pw)
}

func (a *app) passwd() error {
	v, err := a.open()
	if err != nil {
		return err
	}
	fmt.Fprintln(os.Stderr, "New password:")
	os.Unsetenv("CS_PASSWORD")
	pw, err := password(true)
	if err != nil {
		return err
	}
	return v.ChangePassword(pw, vault.DefaultKDF)
}

func (a *app) engine(ctx context.Context) (*engine.Engine, error) {
	v, err := a.open()
	if err != nil {
		return nil, err
	}
	dir := a.dataDir
	if dir == "" {
		dir = filepath.Join(filepath.Dir(a.vaultPath), "data-"+v.Config().VaultID[:8])
	}
	return engine.Open(ctx, v, engine.Options{DataDir: dir, DeviceName: a.device, Platform: runtime.GOOS})
}

func (a *app) backend(ctx context.Context, args []string) error {
	if len(args) == 0 {
		return errors.New("usage: cs backend add|ls|types|disable|enable|reconnect")
	}
	if args[0] == "types" {
		fmt.Println(strings.Join(backend.Types(), " "))
		return nil
	}
	v, err := a.open()
	if err != nil {
		return err
	}
	switch args[0] {
	case "ls":
		c := v.Config()
		tw := tabwriter.NewWriter(os.Stdout, 0, 4, 2, ' ', 0)
		fmt.Fprintln(tw, "ID\tNAME\tTYPE\tDOMAIN\tSTATE")
		for _, b := range c.Backends {
			state := "active"
			if b.Disabled {
				state = "disabled"
			}
			fmt.Fprintf(tw, "%s\t%s\t%s\t%s\t%s\n", b.ID, b.Name, b.Type, b.FailureDomain(), state)
		}
		tw.Flush()
		warn(c)
		return nil
	case "add":
		fl := flag.NewFlagSet("backend add", flag.ExitOnError)
		name := fl.String("name", "", "display name")
		typ := fl.String("type", "", "rclone type: drive, mega, s3, webdav, ...")
		domain := fl.String("domain", "", "failure domain (default: type)")
		root := fl.String("root", "cloudsync", "folder inside the account")
		fl.Parse(args[1:])
		if *name == "" || *typ == "" {
			return errors.New("-name and -type are required")
		}
		params := map[string]string{}
		for _, kv := range fl.Args() {
			k, val, ok := strings.Cut(kv, "=")
			if !ok {
				return fmt.Errorf("bad option %q, want key=value", kv)
			}
			params[k] = val
		}
		params, err := backend.ObscureParams(*typ, params)
		if err != nil {
			return err
		}
		if params, err = backend.CompleteParams(ctx, *typ, params); err != nil {
			return err
		}
		if err := backend.CheckRoot(*typ, *root); err != nil {
			return err
		}
		b := vault.Backend{ID: crypto.RandomID(6), Name: *name, Type: *typ, Domain: *domain, Root: *root, Params: params}
		b.Account = backend.AccountFromParams(b.Type, b.Params)
		if b.Account == "" && b.Params["token"] != "" {
			b.Account, _ = backend.WhoAmI(ctx, b.Type, b.Params)
		}
		for _, o := range v.Config().Backends {
			if backend.SameLocation(o, b) {
				return fmt.Errorf("storage %q (%s) already uses this account or folder", o.Name, o.ID)
			}
		}
		// Check access before saving.
		s, err := backend.OpenRclone(ctx, v.Config().VaultID, backend.SharePacing(b, v.Config().Backends), nil)
		if err != nil {
			return err
		}
		if _, err := s.ListDirs(ctx, "j"); err != nil {
			return fmt.Errorf("storage not reachable: %w", err)
		}
		if err := v.Update(func(c *vault.Config) error {
			c.Backends = append(c.Backends, b)
			return nil
		}); err != nil {
			return err
		}
		fmt.Println("added", b.ID)
		warn(v.Config())
		return nil
	case "reconnect":
		if len(args) != 2 {
			return errors.New("usage: cs backend reconnect ID")
		}
		account, err := backend.Reconnect(ctx, v, args[1], func(url string) error {
			fmt.Println("open in a browser on this device:", url)
			return nil
		})
		if err != nil {
			return err
		}
		fmt.Println("reconnected", args[1], account)
		return nil
	case "disable", "enable":
		if len(args) != 2 {
			return fmt.Errorf("usage: cs backend %s ID", args[0])
		}
		err := v.Update(func(c *vault.Config) error {
			for i := range c.Backends {
				if c.Backends[i].ID == args[1] {
					c.Backends[i].Disabled = args[0] == "disable"
					return nil
				}
			}
			return fmt.Errorf("no backend %s", args[1])
		})
		if err == nil && args[0] == "disable" {
			fmt.Println("disabled; run 'cs repair' to move its shards to the other storages")
		}
		return err
	}
	return fmt.Errorf("unknown backend command %q", args[0])
}

func warn(c *vault.Config) {
	n := len(c.ActiveBackends())
	if need := c.DataShards + c.ParityShards; n < need {
		fmt.Printf("note: %d of %d storages needed for k=%d m=%d\n", n, need, c.DataShards, c.ParityShards)
	} else if engine.DomainRisk(c) {
		fmt.Println("warning: one provider holds more than m shards; its outage would make files unreadable")
	}
}

func status(ctx context.Context, e *engine.Engine) error {
	st := e.Status(ctx)
	sp := e.Space(ctx)
	space := map[string]engine.BackendSpace{}
	for _, b := range sp.Backends {
		space[b.ID] = b
	}
	fmt.Printf("device %s (%s), k=%d m=%d, pending changes: %d\n", st.Device.Name, st.Device.ID, st.DataShards, st.ParityShards, st.Pending)
	writable := "unknown (no storage reports its space)"
	if sp.Writable >= 0 {
		writable = sizeText(sp.Writable)
	}
	fmt.Printf("files: %s, room for about %s more\n", sizeText(sp.Files), writable)
	tw := tabwriter.NewWriter(os.Stdout, 0, 4, 2, ' ', 0)
	fmt.Fprintln(tw, "STORAGE\tTYPE\tDOMAIN\tVAULT DATA\tFREE / TOTAL\tSTATE")
	for _, b := range st.Backends {
		state := "online"
		if b.Behind {
			state = "online, missing data (new or wiped: run 'cs repair')"
		}
		if !b.Online {
			state = "offline: " + b.Error
		}
		bs := space[b.ID]
		room := "?"
		if bs.Known {
			room = sizeText(bs.Free)
			if bs.Total >= 0 {
				room += " / " + sizeText(bs.Total)
			}
		}
		fmt.Fprintf(tw, "%s\t%s\t%s\t%s\t%s\t%s\n", b.Name, b.Type, b.Domain, sizeText(bs.Stored), room, state)
	}
	tw.Flush()
	fmt.Println("devices:")
	for _, d := range e.Config().Devices {
		fmt.Printf("  %s %s (%s) added %s\n", d.ID, d.Name, d.Platform, d.Added.Format("2006-01-02"))
	}
	if st.DomainRisk {
		fmt.Println("warning: one provider holds more than m shards of a blob")
	}
	if st.ReloadNeeded {
		fmt.Println("the vault changed on another device; run the command again to use it")
	}
	return nil
}

func ls(e *engine.Engine, args []string) error {
	fl := flag.NewFlagSet("ls", flag.ExitOnError)
	long := fl.Bool("l", false, "long format")
	fl.Parse(args)
	p := "/"
	if fl.NArg() > 0 {
		p = fl.Arg(0)
	}
	en, err := e.Stat(p)
	if err != nil {
		return err
	}
	list := []index.Entry{en}
	if en.Dir {
		list, _ = e.List(p)
	}
	tw := tabwriter.NewWriter(os.Stdout, 0, 4, 2, ' ', 0)
	for _, c := range list {
		name := c.Name()
		if c.Dir {
			name += "/"
		}
		if !*long {
			fmt.Fprintln(tw, name)
			continue
		}
		size, mtime, flags := "-", c.Time, ""
		if c.Version != nil {
			size, mtime = fmt.Sprint(c.Version.Size), c.Version.ModTime
			if e.IsLocal(c.Path) {
				flags += "L"
			}
		}
		if e.IsPinned(c.Path) {
			flags += "P"
		}
		fmt.Fprintf(tw, "%s\t%s\t%s\t%s\n", flags, size, mtime.Local().Format("2006-01-02 15:04:05"), name)
	}
	return tw.Flush()
}

func put(ctx context.Context, e *engine.Engine, args []string) error {
	if len(args) < 2 {
		return errors.New("usage: cs put LOCAL... REMOTE_DIR")
	}
	ups, err := engine.LocalUploads(args[:len(args)-1], args[len(args)-1])
	if err != nil {
		return err
	}
	start := time.Now()
	out, err := e.PutFiles(ctx, ups)
	if err != nil {
		return err
	}
	fmt.Printf("%d files stored in %s\n", len(out), time.Since(start).Round(time.Millisecond))
	if n := e.Pending(); n > 0 {
		fmt.Printf("%d changes not uploaded yet (storages unreachable); run 'cs sync' later\n", n)
	}
	return nil
}

// sizeText prints bytes in binary units (1.5 GiB).
func sizeText(n int64) string {
	const unit = 1024
	if n < unit {
		return fmt.Sprintf("%d B", n)
	}
	div, exp := int64(unit), 0
	for m := n / unit; m >= unit && exp < 4; m /= unit {
		div *= unit
		exp++
	}
	return fmt.Sprintf("%.1f %ciB", float64(n)/float64(div), "KMGTP"[exp])
}
