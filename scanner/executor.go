package scanner

import (
	"bufio"
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"strings"
	"syscall"
	"text/template"

	log "github.com/sirupsen/logrus"
)

type Bench struct {
	Script     Script
	daemonOpts []string
	childCmd   *exec.Cmd
}

type DockerReplaceOpts struct {
	Replace_docker_daemon_opts string
	Replace_container_list     string
}

type benchItem struct {
	Level             string
	TestNum           string
	Group             string
	Header            string
	Profile           string // level 1, 2
	Scored            bool
	Automated         bool
	Message           string
	Remediation       string
	RemediationImpact string
	TestCategory      string
}

func (b *Bench) RunScripts() ([]benchItem, error) {
	for _, destPath := range b.Script.Files {

		var errb, outb bytes.Buffer
		cmd := exec.Command("bash", destPath)
		cmd.Env = os.Environ()
		for _, variable := range b.Script.Vars {
			value := os.Getenv(variable)
			if value != "" {
				cmd.Env = append(cmd.Env, fmt.Sprintf("%s=%s", variable, value))
			}
		}
		cmd.SysProcAttr = &syscall.SysProcAttr{Setsid: true}
		cmd.Stdout = &outb
		cmd.Stderr = &errb
		b.childCmd = cmd

		err := cmd.Start()
		if err != nil {
			log.WithFields(log.Fields{"error": err, "msg": errb.String()}).Error("Start")
			return nil, err
		}
		// global.SYS.AddToolProcess(pgid, 1, "host-bench", destPath)
		err = cmd.Wait()
		out := outb.Bytes()

		b.childCmd = nil
		if err != nil || len(out) == 0 {
			if err == nil {
				err = fmt.Errorf("error executing script")
			}
			log.WithFields(log.Fields{"error": err, "msg": errb.String()}).Error("Done")
			return nil, err
		}
		items := b.getBenchMsg(out)
		for _, item := range items {
			s, err := json.Marshal(item)
			if err != nil {
				log.Error(err.Error())
				continue
			}
			log.Debug(string(s))
		}
		return items, nil
	}
	return nil, nil
}

// replace the docker daemon config line, so that can run the script without pid=host
func (b *Bench) replaceTemplateVars(srcPath, dstPath string, containers []string) error {
	dat, err := ioutil.ReadFile(srcPath)
	if err != nil {
		return err
	}
	f, err := os.Create(dstPath)
	if err != nil {
		return err
	}
	defer f.Close()

	//containers only apply to container.sh, no effect to host.sh, because no <<<Containers>>> in it
	var containerLines string
	if len(containers) > 0 {
		containerLines = "containers=\"\n" + strings.Join(containers, "\n") + "\"\n"
	} else {
		containerLines = "containers=\"\"\n"
	}
	r := DockerReplaceOpts{
		Replace_docker_daemon_opts: strings.Join(b.daemonOpts, " "),
		Replace_container_list:     containerLines,
	}
	t := template.New("bench")
	t.Delims("<<<", ">>>")
	t.Parse(string(dat))

	if err = t.Execute(f, r); err != nil {
		log.WithFields(log.Fields{"error": err}).Error("Executing template error")
		return err
	}
	return nil
}

func (b *Bench) getBenchMsg(out []byte) []benchItem {
	list := make([]benchItem, 0)
	scanner := bufio.NewScanner(strings.NewReader(string(out)))
	for scanner.Scan() {
		// Read output line-by-line. Every check forms a item,
		// the first line is the header and the rest form the message
		line := scanner.Text()
		var item benchItem
		err := json.Unmarshal([]byte(line), &item)
		if err == nil && b.acceptBenchItem(&item, nil) {
			list = append(list, item)
		}
	}
	return list
}

// check if last item should be accepted or ignored
func (b *Bench) acceptBenchItem(last, item *benchItem) bool {
	/*if last == nil {
		return false
	}
	// 1.2 should be ignored if the next line has 1.2. prefix
	if item != nil && strings.HasPrefix(item.TestNum, fmt.Sprintf("%s.", last.TestNum)) {
		return false
	}
	// Ignore NOTE and INFO entries
	if last.Level == share.BenchLevelNote || last.Level == share.BenchLevelInfo {
		return false
	}*/
	return true
}
