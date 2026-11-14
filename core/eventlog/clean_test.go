package eventlog

import (
	"strings"
	"testing"
)

func TestCleanHTML(t *testing.T) {
	msg := "OneDrive: get d: HTTP error 401 (401 Unauthorized) <html><head><META HTTP-EQUIV=\"Content-Type\" CONTENT=\"text/html\"></head><body>An unexpected error has occurred.</body>\n" +
		"   <script type=\"text/javascript\" nonce='x'>\n var gearPage = document.getElementById('GearPage');\n if(null != gearPage) { gearPage.parentNode.removeChild(gearPage); }\n </script>\n</html>"
	got := Clean(msg)
	if want := "OneDrive: get d: HTTP error 401 (401 Unauthorized) An unexpected error has occurred."; got != want {
		t.Fatalf("got %q, want %q", got, want)
	}
	plain := "Yandex Disk: list j: [410 - GoneError] Gone\nsecond <error>"
	if got := Clean(plain); got != plain {
		t.Fatalf("plain text changed: %q", got)
	}
	if got := Clean(strings.Repeat("a", 2000)); len([]rune(got)) != maxMessage+1 {
		t.Fatalf("not capped: %d", len(got))
	}
}
