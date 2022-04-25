package main

import (
	"bufio"
	"bytes"
	"fmt"
	"github.com/deepfence/compliance/global"
	"github.com/deepfence/compliance/share"
	log "github.com/sirupsen/logrus"
	"io/ioutil"
	"os"
	"os/exec"
	"strings"
	"syscall"
	"text/template"
)

type Bench struct {
	script Script
	daemonOpts      []string
	childCmd        *exec.Cmd
}

type DockerReplaceOpts struct {
	Replace_docker_daemon_opts string
	Replace_container_list     string
}

type benchItem struct {
	level       string
	testNum     string
	group       string
	header      string
	profile     string // level 1, 2
	scored      bool
	automated   bool
	message     []string
	remediation string
}

func (b *Bench) runScript() {
	/*var errb, outb bytes.Buffer
	args := []string{
		system.NSActRun, "-f", script,
		"-m", global.SYS.GetMountNamespacePath(1),
		"-n", global.SYS.GetNetNamespacePath(1),
	}
	log.WithFields(log.Fields{"type": bench}).Debug("Running Kubernetes CIS bench")
	cmd := exec.Command(system.ExecNSTool, args...)
	cmd.SysProcAttr = &syscall.SysProcAttr{Setsid: true}
	cmd.Stdout = &outb
	cmd.Stderr = &errb
	b.childCmd = cmd
	err := cmd.Start()
	if err != nil {
		log.WithFields(log.Fields{"error": err, "msg": errb.String()}).Error("Start")
		return nil, err
	}
	pgid := cmd.Process.Pid
	global.SYS.AddToolProcess(pgid, 1, "kube-bench", script)
	err = cmd.Wait()
	global.SYS.RemoveToolProcess(pgid, false)
	out := outb.Bytes()

	b.childCmd = nil
	if err != nil {
		if ee, ok := err.(*exec.ExitError); ok {
			status := global.SYS.GetExitStatus(ee)
			if status == 2 {
				// Not a master or worker node, ignore the error
				log.WithFields(log.Fields{"msg": errb.String()}).Debug("Done")
				return nil, fmt.Errorf("Node type not recognized")
			}
		}

		log.WithFields(log.Fields{"error": err, "msg": errb.String()}).Error("")
		return nil, err
	}

	log.WithFields(log.Fields{"type": bench}).Debug("Finish Kubernetes CIS bench")
	return out, nil*/
}

func (b *Bench) RunScripts() ([]byte, error) {
	for _, tmplFile := range b.script.Files {
		destPath := strings.Replace(tmplFile, ".tmpl", ".sh", -1)
		err := b.replaceTemplateVars(tmplFile, destPath, nil)
		if err != nil {
			return nil, err
		}
		args := []string{"run", "-f", destPath}
		/*,
			"-m", global.SYS.GetMountNamespacePath(1), "-n", global.SYS.GetNetNamespacePath(1)}
		*/
		var errb, outb bytes.Buffer
		cmd := exec.Command("/usr/local/bin/nstools", args...)
		cmd.SysProcAttr = &syscall.SysProcAttr{Setsid: true}
		cmd.Stdout = &outb
		cmd.Stderr = &errb
		b.childCmd = cmd

		err = cmd.Start()
		if err != nil {
			log.WithFields(log.Fields{"error": err, "msg": errb.String()}).Error("Start")
			return nil, err
		}
		pgid := cmd.Process.Pid
		// global.SYS.AddToolProcess(pgid, 1, "host-bench", destPath)
		err = cmd.Wait()
		global.SYS.RemoveToolProcess(pgid, false)
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
		fmt.Println("Sending items to stdout:")
		for _, item := range items {
			fmt.Println(item)
		}
		return out, nil
	}
	return nil, nil
}

//replace the docker daemon config line, so that can run the script without pid=host
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

func (b *Bench) getBenchMsg(out []byte) []*benchItem {
	list := make([]*benchItem, 0)
	scanner := bufio.NewScanner(strings.NewReader(string(out)))
	var last, item *benchItem
	for scanner.Scan() {
		// Read output line-by-line. Every check forms a item,
		// the first line is the header and the rest form the message
		line := scanner.Text()
		if c, ok := b.parseBenchMsg(line); ok {
			if c.testNum == "" && item != nil {
				item.message = append(item.message, c.header)
			} else {
				if item != nil {
					// add the last item to the result
					if b.acceptBenchItem(last, item) {
						list = append(list, last)
					}
					last = item
				}
				item = c
			}
		}
	}
	if item != nil {
		// add the last item to the result
		if b.acceptBenchItem(last, item) {
			list = append(list, last)
		}
		if b.acceptBenchItem(item, nil) {
			list = append(list, item)
		}
	}
	return list
}

// check if last item should be accepted or ignored
func (b *Bench) acceptBenchItem(last, item *benchItem) bool {
	if last == nil {
		return false
	}
	// 1.2 should be ignored if the next line has 1.2. prefix
	if item != nil && strings.HasPrefix(item.testNum, fmt.Sprintf("%s.", last.testNum)) {
		return false
	}
	// Ignore NOTE and INFO entries
	if last.level == share.BenchLevelNote || last.level == share.BenchLevelInfo {
		return false
	}
	return true
}