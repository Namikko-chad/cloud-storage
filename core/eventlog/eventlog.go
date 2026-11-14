// Package eventlog keeps the recent events of the core in memory (and
// optionally mirrors them to a writer), so the app can show why a storage
// went offline or a sync failed.
package eventlog

import (
	"fmt"
	"io"
	"sync"
	"time"
)

// Levels.
const (
	Info  = "info"
	Warn  = "warn"
	Error = "error"
)

// Entry is one event. Repeats of the same event are folded into one entry
// (Count, Time is the last occurrence, First the first one).
type Entry struct {
	Seq       uint64
	Time      time.Time
	First     time.Time
	Level     string
	Source    string // "sync", "mount", "storage", ...
	BackendID string // set for events of one storage
	Message   string
	Count     int
}

// Log is a bounded, concurrency-safe event list. The zero value is not
// usable; use New. A nil *Log ignores everything.
type Log struct {
	mu   sync.Mutex
	max  int
	seq  uint64
	list []Entry
	out  io.Writer
}

// New returns a log keeping the last max entries; out (may be nil) gets
// every new entry as a line.
func New(max int, out io.Writer) *Log {
	if max <= 0 {
		max = 1000
	}
	return &Log{max: max, out: out}
}

// Add records an event. An event equal to one of the last few entries
// (same level, source, storage and message) only bumps its count, so a
// storage that is down does not flood the log.
func (l *Log) Add(level, source, backendID, msg string) {
	if l == nil {
		return
	}
	msg = Clean(msg)
	now := time.Now()
	l.mu.Lock()
	defer l.mu.Unlock()
	for i := len(l.list) - 1; i >= 0 && i >= len(l.list)-8; i-- {
		e := &l.list[i]
		if e.Level == level && e.Source == source && e.BackendID == backendID && e.Message == msg {
			e.Count++
			e.Time = now
			l.seq++
			e.Seq = l.seq
			// Move it to the end: it is the latest event now.
			moved := *e
			l.list = append(append(l.list[:i], l.list[i+1:]...), moved)
			return
		}
	}
	l.seq++
	l.list = append(l.list, Entry{Seq: l.seq, Time: now, First: now, Level: level, Source: source, BackendID: backendID, Message: msg, Count: 1})
	if len(l.list) > l.max {
		l.list = append([]Entry(nil), l.list[len(l.list)-l.max:]...)
	}
	if l.out != nil {
		id := ""
		if backendID != "" {
			id = " [" + backendID + "]"
		}
		fmt.Fprintf(l.out, "%s %-5s %s%s: %s\n", now.Format(time.RFC3339), level, source, id, msg)
	}
}

// Addf is Add with formatting.
func (l *Log) Addf(level, source, backendID, format string, args ...any) {
	l.Add(level, source, backendID, fmt.Sprintf(format, args...))
}

// Entries returns up to limit latest entries (all when limit <= 0), oldest
// first, optionally only those of one storage.
func (l *Log) Entries(backendID string, limit int) []Entry {
	if l == nil {
		return nil
	}
	l.mu.Lock()
	defer l.mu.Unlock()
	var out []Entry
	for i := len(l.list) - 1; i >= 0; i-- {
		if backendID != "" && l.list[i].BackendID != backendID {
			continue
		}
		out = append(out, l.list[i])
		if limit > 0 && len(out) == limit {
			break
		}
	}
	for i, j := 0, len(out)-1; i < j; i, j = i+1, j-1 {
		out[i], out[j] = out[j], out[i]
	}
	return out
}

// Clear drops every entry.
func (l *Log) Clear() {
	if l == nil {
		return
	}
	l.mu.Lock()
	l.list = nil
	l.mu.Unlock()
}
