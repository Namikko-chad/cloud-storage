package eventlog

import "testing"

func TestFoldAndLimit(t *testing.T) {
	l := New(3, nil)
	l.Add(Error, "storage", "a", "down")
	l.Add(Info, "sync", "", "ok")
	l.Add(Error, "storage", "a", "down")
	got := l.Entries("", 0)
	if len(got) != 2 || got[1].Message != "down" || got[1].Count != 2 {
		t.Fatalf("fold: %+v", got)
	}
	l.Add(Info, "x", "", "1")
	l.Add(Info, "x", "", "2")
	if got := l.Entries("", 0); len(got) != 3 || got[0].Message != "down" {
		t.Fatalf("limit: %+v", got)
	}
	if got := l.Entries("a", 0); len(got) != 1 {
		t.Fatalf("filter: %+v", got)
	}
	if got := l.Entries("", 1); len(got) != 1 || got[0].Message != "2" {
		t.Fatalf("latest: %+v", got)
	}
}
