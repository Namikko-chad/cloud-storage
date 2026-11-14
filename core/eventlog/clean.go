package eventlog

import (
	"regexp"
	"strings"
)

var (
	htmlStart  = regexp.MustCompile(`(?i)<(html|!doctype|head|body)[\s>]`)
	htmlBlocks = regexp.MustCompile(`(?is)<(script|style)\b.*?(</(script|style)>|$)`)
	htmlTags   = regexp.MustCompile(`<[^>]*>`)
	blanks     = regexp.MustCompile(`[ \t\r]+`)
	blankLines = regexp.MustCompile(`\n\s*\n+`)
)

// maxMessage caps one event text: a provider may answer with a whole page.
const maxMessage = 600

// Clean makes an error text fit for a person: an HTML page some providers
// send as an error body (OneDrive's 401) is reduced to its visible text,
// runs of blanks are collapsed and the result is capped.
func Clean(msg string) string {
	if htmlStart.MatchString(msg) {
		msg = htmlBlocks.ReplaceAllString(msg, " ")
		msg = htmlTags.ReplaceAllString(msg, " ")
		msg = blanks.ReplaceAllString(msg, " ")
		msg = blankLines.ReplaceAllString(msg, "\n")
		lines := strings.Split(msg, "\n")
		for i := range lines {
			lines[i] = strings.TrimSpace(lines[i])
		}
		msg = strings.Join(lines, "\n")
	}
	msg = strings.TrimSpace(msg)
	if r := []rune(msg); len(r) > maxMessage {
		msg = string(r[:maxMessage]) + "…"
	}
	return msg
}
