package compliance

import (
	"github.com/deepfence/compliance/share"
	"strings"
)

func (b *Bench) parseBenchMsg(line string) (*benchItem, bool) {
	var level, id, msg, profile string
	var scored, automated bool

	if strings.Contains(line, "[INFO]") {
		level = share.BenchLevelInfo
	} else if strings.Contains(line, "[PASS]") {
		level = share.BenchLevelPass
	} else if strings.Contains(line, "[WARN]") {
		level = share.BenchLevelWarn
	} else if strings.Contains(line, "[NOTE]") {
		level = share.BenchLevelNote
	} else {
		return nil, false
	}

	a := strings.Index(line, "0m ")
	if a == -1 {
		return nil, false
	}
	c := strings.Index(line, " - ")
	if c != -1 {
		// Item headline
		id = strings.TrimSpace(line[a+3 : c])

		// Ignore the section title
		if strings.Index(id, ".") == -1 {
			return nil, false
		}

		if x := strings.Index(line, "[Scored]"); x != -1 {
			scored = true
		}
		if x := strings.Index(line, "[Automated]"); x != -1 {
			automated = true
		}
		if x := strings.Index(line, "[Level 1]"); x != -1 {
			profile = share.BenchProfileL1
		} else if x = strings.Index(line, "[Level 2]"); x != -1 {
			profile = share.BenchProfileL2
		}
	} else {
		// Item's following line
		c = strings.Index(line, " * ")
		if c == -1 {
			return nil, false
		}
	}

	msg = line[c+3:]
	msg = strings.ReplaceAll(msg, "(Scored)", "")
	msg = strings.ReplaceAll(msg, "(Not Scored)", "")
	msg = strings.ReplaceAll(msg, "(Automated)", "")
	msg = strings.ReplaceAll(msg, "(Manual)", "")
	msg = strings.TrimSpace(msg)

	return &benchItem{
		level: level, testNum: id, header: msg,
		scored: scored, automated: automated, profile: profile,
	}, true
}