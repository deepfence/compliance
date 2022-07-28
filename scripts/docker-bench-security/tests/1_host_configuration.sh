#!/bin/bash

check_1() {
  logit ""
  local id="1"
  local desc="Host Configuration"
  checkHeader="$id - $desc"
  info "$checkHeader"
  startsectionjson "$id" "$desc"
}

check_1_1() {
  local id="1.1"
  local desc="Linux Hosts Specific Configuration"
  local check="$id - $desc"
  info "$check"
}

check_1_1_1() {
  local id="1.1.1"
  local desc="Ensure a separate partition for containers has been created (Automated)"
  local remediation="For new installations, you should create a separate partition for the /var/lib/docker mount point. For systems that have already been installed, you should use the Logical Volume Manager (LVM) within Linux to create a new partition."
  local remediationImpact="None."
  local testCategory="Docker Configuration"
  local check="$id - $desc - $testCategory"

  docker_root_dir=$(docker info -f '{{ .DockerRootDir }}')
  if docker info | grep -q userns ; then
    docker_root_dir=$(readlink -f "$docker_root_dir/..")
  fi

  if mountpoint -q -- "$docker_root_dir" >/dev/null 2>&1; then
    logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
    return
  fi
  logbenchjson "WARN"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
}

check_1_1_2() {
  local id="1.1.2"
  local desc="Ensure only trusted users are allowed to control Docker daemon (Automated)"
  local remediation="You should remove any untrusted users from the docker group using command sudo gpasswd -d <your-user> docker or add trusted users to the docker group using command sudo usermod -aG docker <your-user>. You should not create a mapping of sensitive directories from the host to container volumes."
  local remediationImpact="Only trust user are allow to build and execute containers as normal user."
  local testCategory="User Settings"
  local check="$id - $desc - $testCategory"
  starttestjson "$id" "$desc"

  docker_users=$(grep 'docker' /fenced/mnt/host/etc/group)
  if command -v getent >/dev/null 2>&1; then
    docker_users=$(getent group docker)
  fi
  docker_users=$(printf "%s" "$docker_users" | awk -F: '{print $4}')

  local doubtfulusers=""
  if [ -n "$dockertrustusers" ]; then
    for u in $(printf "%s" "$docker_users" | sed "s/,/ /g"); do
      if ! printf "%s" "$dockertrustusers" | grep -q "$u" ; then
        doubtfulusers="$u"
        if [ -n "${doubtfulusers}" ]; then
          doubtfulusers="${doubtfulusers},$u"
        fi
      fi
    done
  else
    logbenchjson "INFO"  $id "$testCategory" "$desc" "* Users: $docker_users" "$remediation" "$remediationImpact"
  fi

  if [ -n "${doubtfulusers}" ]; then
    logbenchjson "WARN"  $id "$testCategory" "$desc" " * Users: $doubtfulusers" "$remediation" "$remediationImpact"
  fi

  if [ -z "${doubtfulusers}" ] && [ -n "${dockertrustusers}" ]; then
    logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
  fi
}

check_1_1_3() {
  local id="1.1.3"
  local desc="Ensure auditing is configured for the Docker daemon (Automated)"
  local remediation="Install auditd. Add -w /usr/bin/dockerd -k docker to the /fenced/mnt/host/etc/audit/rules.d/audit.rules file. Then restart the audit daemon using command service auditd restart."
  local remediationImpact="Audit can generate large log files. So you need to make sure that they are rotated and archived periodically. Create a separate partition for audit logs to avoid filling up other critical partitions."
  local testCategory="Audit"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  file="/usr/bin/dockerd"
  if command -v auditctl >/dev/null 2>&1; then
    if auditctl -l | grep "$file" >/dev/null 2>&1; then
      logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
      return
    fi
    logbenchjson "WARN"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
    return
  fi
  if grep -s "$file" "$auditrules" | grep "^[^#;]" 2>/dev/null 1>&2; then
    logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
    return
  fi
  logbenchjson "WARN"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
}

check_1_1_4() {
  local id="1.1.4"
  local desc="Ensure auditing is configured for Docker files and directories -/run/containerd (Automated)"
  local remediation="Install auditd. Add -a exit,always -F path=/run/containerd -F perm=war -k docker to the /fenced/mnt/host/etc/audit/rules.d/audit.rules file. Then restart the audit daemon using command service auditd restart."
  local remediationImpact="Audit can generate large log files. So you need to make sure that they are rotated and archived periodically. Create a separate partition for audit logs to avoid filling up other critical partitions."
  local testCategory="Audit"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  file="/run/containerd"
  if command -v auditctl >/dev/null 2>&1; then
    if auditctl -l | grep "$file" >/dev/null 2>&1; then
      logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
      return
    fi
    logbenchjson "WARN"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
    return
  fi
  if grep -s "$file" "$auditrules" | grep "^[^#;]" 2>/dev/null 1>&2; then
   logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
    return
  fi
  logbenchjson "WARN"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
}

check_1_1_5() {
  local id="1.1.5"
  local desc="Ensure auditing is configured for Docker files and directories - /var/lib/docker (Automated)"
  local remediation="Install auditd. Add -w /var/lib/docker -k docker to the /fenced/mnt/host/etc/audit/rules.d/audit.rules file. Then restart the audit daemon using command service auditd restart."
  local remediationImpact="Audit can generate large log files. So you need to make sure that they are rotated and archived periodically. Create a separate partition for audit logs to avoid filling up other critical partitions."
  local check="$id - $desc"
  local testCategory="Audit"
  starttestjson "$id" "$desc"

  directory="/var/lib/docker"
  if [ -d "$directory" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l | grep $directory >/dev/null 2>&1; then
        logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
        return
      fi
      logbenchjson "WARN"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
      return
    fi
    if grep -s "$directory" "$auditrules" | grep "^[^#;]" 2>/dev/null 1>&2; then
      logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
      return
    fi
    logbenchjson "WARN"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
    return
  fi
  logbenchjson "INFO"  $id "$testCategory" "$desc" "** Directory Not Found" "$remediation" "$remediationImpact"
}

check_1_1_6() {
  local id="1.1.6"
  local desc="Ensure auditing is configured for Docker files and directories - /fenced/mnt/host/etc/docker (Automated)"
  local remediation="Install auditd. Add -w /fenced/mnt/host/etc/docker -k docker to the /fenced/mnt/host/etc/audit/rules.d/audit.rules file. Then restart the audit daemon using command service auditd restart."
  local remediationImpact="Audit can generate large log files. So you need to make sure that they are rotated and archived periodically. Create a separate partition for audit logs to avoid filling up other critical partitions."
  local check="$id - $desc"
  local testCategory="Audit"
  starttestjson "$id" "$desc"

  directory="/fenced/mnt/host/etc/docker"
  if [ -d "$directory" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l | grep $directory >/dev/null 2>&1; then
        logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
        return
      fi
      logbenchjson "WARN"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
      return
    fi
    if grep -s "$directory" "$auditrules" | grep "^[^#;]" 2>/dev/null 1>&2; then
      logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
      return
    fi
    logbenchjson "WARN"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
    return
  fi
  logbenchjson "INFO"  $id "$testCategory" "$desc" "** Directory Not Found" "$remediation" "$remediationImpact"
}

check_1_1_7() {
  local id="1.1.7"
  local desc="Ensure auditing is configured for Docker files and directories - docker.service (Automated)"
  local remediation
  remediation="Install auditd. Add -w $(get_service_file docker.service) -k docker to the /fenced/mnt/host/etc/audit/rules.d/audit.rules file. Then restart the audit daemon using command service auditd restart."
  local remediationImpact="Audit can generate large log files. So you need to make sure that they are rotated and archived periodically. Create a separate partition for audit logs to avoid filling up other critical partitions."
  local check="$id - $desc"
  local testCategory="Audit"
  starttestjson "$id" "$desc"

  file="$(get_service_file docker.service)"
  if [ -f "$file" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l | grep "$file" >/dev/null 2>&1; then
        logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
        return
      fi
      logbenchjson "WARN"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
      return
    fi
    if grep -s "$file" "$auditrules" | grep "^[^#;]" 2>/dev/null 1>&2; then
      logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
      return
    fi
    logbenchjson "WARN"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
    return
  fi
  logbenchjson "PASS"  $id "$testCategory" "$desc" "- File Not Found" "$remediation" "$remediationImpact"
}

check_1_1_8() {
  local id="1.1.8"
  local desc="Ensure auditing is configured for Docker files and directories - containerd.sock (Automated)"
  local remediation
  remediation="Install auditd. Add -w $(get_service_file containerd.socket) -k docker to the /fenced/mnt/host/etc/audit/rules.d/audit.rules file. Then restart the audit daemon using command service auditd restart."
  local remediationImpact="Audit can generate large log files. So you need to make sure that they are rotated and archived periodically. Create a separate partition for audit logs to avoid filling up other critical partitions."
  local check="$id - $desc"
  local testCategory="Audit"

  file="$(get_service_file containerd.socket)"
  if [ -e "$file" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l | grep "$file" >/dev/null 2>&1; then
        logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
        return
      fi
      logbenchjson "WARN"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
      return
    fi
    if grep -s "$file" "$auditrules" | grep "^[^#;]" 2>/dev/null 1>&2; then
      logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
      return
    fi
    logbenchjson "WARN"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
    return
  fi
  logbenchjson "INFO"  $id "$testCategory" "$desc" "- File Not Found" "$remediation" "$remediationImpact"
}
check_1_1_9() {
  local id="1.1.9"
  local desc="Ensure auditing is configured for Docker files and directories - docker.socket (Automated)"
  local remediation
  remediation="Install auditd. Add -w $(get_service_file docker.socket) -k docker to the /fenced/mnt/host/etc/audit/rules.d/audit.rules file. Then restart the audit daemon using command service auditd restart."
  local remediationImpact="Audit can generate large log files. So you need to make sure that they are rotated and archived periodically. Create a separate partition for audit logs to avoid filling up other critical partitions."
  local check="$id - $desc"
  local testCategory="Audit"
  starttestjson "$id" "$desc"

  file="$(get_service_file docker.socket)"
  if [ -e "$file" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l | grep "$file" >/dev/null 2>&1; then
        logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
        return
      fi
      logbenchjson "WARN"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
      return
    fi
    if grep -s "$file" "$auditrules" | grep "^[^#;]" 2>/dev/null 1>&2; then
      logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
      return
    fi
    logbenchjson "WARN"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
    return
  fi
  logbenchjson "INFO"  $id "$testCategory" "$desc" "- File Not Found" "$remediation" "$remediationImpact"
}

check_1_1_10() {
  local id="1.1.10"
  local desc="Ensure auditing is configured for Docker files and directories - /fenced/mnt/host/etc/default/docker (Automated)"
  local remediation="Install auditd. Add -w /fenced/mnt/host/etc/default/docker -k docker to the /fenced/mnt/host/etc/audit/rules.d/audit.rules file. Then restart the audit daemon using command service auditd restart."
  local remediationImpact="Audit can generate large log files. So you need to make sure that they are rotated and archived periodically. Create a separate partition for audit logs to avoid filling up other critical partitions."
  local check="$id - $desc"
  local testCategory="Audit"
  starttestjson "$id" "$desc"

  file="/fenced/mnt/host/etc/default/docker"
  if [ -f "$file" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l | grep $file >/dev/null 2>&1; then
        logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
        return
      fi
      logbenchjson "WARN"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
      return
    fi
    if grep -s "$file" "$auditrules" | grep "^[^#;]" 2>/dev/null 1>&2; then
      logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
      return
    fi
    logbenchjson "WARN"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
    return
  fi
  logbenchjson "INFO"  $id "$testCategory" "$desc" "- File Not Found" "$remediation" "$remediationImpact"
}

check_1_1_11() {
  local id="1.1.11"
  local desc="Ensure auditing is configured for Dockerfiles and directories - /fenced/mnt/host/etc/docker/daemon.json (Automated)"
  local remediation="Install auditd. Add -w /fenced/mnt/host/etc/docker/daemon.json -k docker to the /fenced/mnt/host/etc/audit/rules.d/audit.rules file. Then restart the audit daemon using command service auditd restart."
  local remediationImpact="Audit can generate large log files. So you need to make sure that they are rotated and archived periodically. Create a separate partition for audit logs to avoid filling up other critical partitions."
  local check="$id - $desc"
  local testCategory="Audit"
  starttestjson "$id" "$desc"

  file="/fenced/mnt/host/etc/docker/daemon.json"
  if [ -f "$file" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l | grep $file >/dev/null 2>&1; then
        logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
        return
      fi
      logbenchjson "WARN"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
      return
    fi
    if grep -s "$file" "$auditrules" | grep "^[^#;]" 2>/dev/null 1>&2; then
      logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
      return
    fi
    logbenchjson "WARN"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
    return
  fi
  logbenchjson "INFO"  $id "$testCategory" "$desc" "- File Not Found" "$remediation" "$remediationImpact"
}

check_1_1_12() {
  local id="1.1.12"
  local desc="1.1.12 Ensure auditing is configured for Dockerfiles and directories - /fenced/mnt/host/etc/containerd/config.toml (Automated)"
  local remediation="Install auditd. Add -w /fenced/mnt/host/etc/containerd/config.toml -k docker to the /fenced/mnt/host/etc/audit/rules.d/audit.rules file. Then restart the audit daemon using command service auditd restart."
  local remediationImpact="Audit can generate large log files. So you need to make sure that they are rotated and archived periodically. Create a separate partition for audit logs to avoid filling up other critical partitions."
  local check="$id - $desc"
  local testCategory="Audit"
  starttestjson "$id" "$desc"

  file="/fenced/mnt/host/etc/containerd/config.toml"
  if [ -f "$file" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l | grep $file >/dev/null 2>&1; then
        logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
        return
      fi
      logbenchjson "WARN"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
      return
    fi
    if grep -s "$file" "$auditrules" | grep "^[^#;]" 2>/dev/null 1>&2; then
      logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
      return
    fi
    logbenchjson "WARN"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
    return
  fi
  logbenchjson "INFO"  $id "$testCategory" "$desc" "- File Not Found" "$remediation" "$remediationImpact"
}

check_1_1_13() {
  local id="1.1.13"
  local desc="Ensure auditing is configured for Docker files and directories - /etc/sysconfig/docker (Automated)"
  local remediation="Install auditd. Add -w /fenced/mnt/host/etc/sysconfig/docker -k docker to the /fenced/mnt/host/etc/audit/rules.d/audit.rules file. Then restart the audit daemon using command service auditd restart."
  local remediationImpact="Audit can generate large log files. So you need to make sure that they are rotated and archived periodically. Create a separate partition for audit logs to avoid filling up other critical partitions."
  local check="$id - $desc"
  local testCategory="Audit"
  starttestjson "$id" "$desc"

  file="/fenced/mnt/host/etc/sysconfig/docker"
  if [ -f "$file" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l | grep $file >/dev/null 2>&1; then
        logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
        return
      fi
      logbenchjson "WARN"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
      return
    fi
    if grep -s "$file" "$auditrules" | grep "^[^#;]" 2>/dev/null 1>&2; then
      logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
      return
    fi
    logbenchjson "WARN"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
    return
  fi
  logbenchjson "INFO"  $id "$testCategory" "$desc" "** File Not Found" "$remediation" "$remediationImpact"
}

check_1_1_14() {
  local id="1.1.14"
  local desc="Ensure auditing is configured for Docker files and directories - /usr/bin/containerd (Automated)"
  local remediation="Install auditd. Add -w /usr/bin/containerd -k docker to the /fenced/mnt/host/etc/audit/rules.d/audit.rules file. Then restart the audit daemon using command service auditd restart."
  local remediationImpact="Audit can generate large log files. So you need to make sure that they are rotated and archived periodically. Create a separate partition for audit logs to avoid filling up other critical partitions."
  local check="$id - $desc"
  local testCategory="Audit"
  starttestjson "$id" "$desc"

  file="/usr/bin/containerd"
  if [ -f "$file" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l | grep $file >/dev/null 2>&1; then
        logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
        return
      fi
      logbenchjson "WARN"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
      return
    fi
    if grep -s "$file" "$auditrules" | grep "^[^#;]" 2>/dev/null 1>&2; then
      logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
      return
    fi
    logbenchjson "WARN"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
    return
  fi
  logbenchjson "INFO"  $id "$testCategory" "$desc" " ** File Not Found" "$remediation" "$remediationImpact"
}

check_1_1_15() {
  local id="1.1.15"
  local desc="Ensure auditing is configured for Docker files and directories - /usr/bin/containerd-shim (Automated)"
  local remediation="Install auditd. Add -w /usr/bin/containerd-shim -k docker to the /fenced/mnt/host/etc/audit/rules.d/audit.rules file. Then restart the audit daemon using command service auditd restart."
  local remediationImpact="Audit can generate large log files. So you need to make sure that they are rotated and archived periodically. Create a separate partition for audit logs to avoid filling up other critical partitions."
  local check="$id - $desc"
  local testCategory="Audit"
  starttestjson "$id" "$desc"

  file="/usr/bin/containerd-shim"
  if [ -f "$file" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l | grep $file >/dev/null 2>&1; then
        logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
        return
      fi
      logbenchjson "WARN"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
      return
    fi
    if grep -s "$file" "$auditrules" | grep "^[^#;]" 2>/dev/null 1>&2; then
      logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
      return
    fi
    logbenchjson "WARN"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
    return
  fi
  logbenchjson "INFO"  $id "$testCategory" "$desc" " ** File Not Found" "$remediation" "$remediationImpact"
}

check_1_1_16() {
  local id="1.1.16"
  local desc="Ensure auditing is configured for Docker files and directories - /usr/bin/containerd-shim-runc-v1 (Automated)"
  local remediation="Install auditd. Add -w /usr/bin/containerd-shim-runc-v1 -k docker to the /fenced/mnt/host/etc/audit/rules.d/audit.rules file. Then restart the audit daemon using command service auditd restart."
  local remediationImpact="Audit can generate large log files. So you need to make sure that they are rotated and archived periodically. Create a separate partition for audit logs to avoid filling up other critical partitions."
  local check="$id - $desc"
  local testCategory="Audit"
  starttestjson "$id" "$desc"

  file="/usr/bin/containerd-shim-runc-v1"
  if [ -f "$file" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l | grep $file >/dev/null 2>&1; then
        logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
        return
      fi
      logbenchjson "WARN"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
      return
    fi
    if grep -s "$file" "$auditrules" | grep "^[^#;]" 2>/dev/null 1>&2; then
      logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
      return
    fi
    logbenchjson "WARN"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
    return
  fi
  logbenchjson "INFO"  $id "$testCategory" "$desc" "File Not Found" "$remediation" "$remediationImpact"
}

check_1_1_17() {
  local id="1.1.17"
  local desc="Ensure auditing is configured for Docker files and directories - /usr/bin/containerd-shim-runc-v2 (Automated)"
  local remediation="Install auditd. Add -w /usr/bin/containerd-shim-runc-v2 -k docker to the /fenced/mnt/host/etc/audit/rules.d/audit.rules file. Then restart the audit daemon using command service auditd restart."
  local remediationImpact="Audit can generate large log files. So you need to make sure that they are rotated and archived periodically. Create a separate partition for audit logs to avoid filling up other critical partitions."
  local check="$id - $desc"
  local testCategory="Audit"
  starttestjson "$id" "$desc"

  file="/usr/bin/containerd-shim-runc-v2"
  if [ -f "$file" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l | grep $file >/dev/null 2>&1; then
        logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
        return
      fi
      logbenchjson "WARN"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
      return
    fi
    if grep -s "$file" "$auditrules" | grep "^[^#;]" 2>/dev/null 1>&2; then
      logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
      return
    fi
    logbenchjson "WARN"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
    return
  fi
  logbenchjson "INFO"  $id "$testCategory" "$desc" " ** File Not Found" "$remediation" "$remediationImpact"
}

check_1_1_18() {
  local id="1.1.18"
  local desc="Ensure auditing is configured for Docker files and directories - /usr/bin/runc (Automated)"
  local remediation="Install auditd. Add -w /usr/bin/runc -k docker to the /fenced/mnt/host/etc/audit/rules.d/audit.rules file. Then restart the audit daemon using command service auditd restart."
  local remediationImpact="Audit can generate large log files. So you need to make sure that they are rotated and archived periodically. Create a separate partition for audit logs to avoid filling up other critical partitions."
  local check="$id - $desc"
  local testCategory="Audit"
  starttestjson "$id" "$desc"

  file="/usr/bin/runc"
  if [ -f "$file" ]; then
    if command -v auditctl >/dev/null 2>&1; then
      if auditctl -l | grep $file >/dev/null 2>&1; then
        logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
        return
      fi
     logbenchjson "WARN"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
      return
    fi
    if grep -s "$file" "$auditrules" | grep "^[^#;]" 2>/dev/null 1>&2; then
      logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
      return
    fi
    logbenchjson "WARN"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
    return
  fi
  logbenchjson "INFO"  $id "$testCategory" "$desc" "File Not Found" "$remediation" "$remediationImpact"
}

check_1_2() {
  local id="1.2"
  local desc="General Configuration"
  local check="$id - $desc"
  info "$check"
}

check_1_2_1() {
  local id="1.2.1"
  local desc="Ensure the container host has been Hardened (Manual)"
  local remediation="You may consider various Security Benchmarks for your container host."
  local remediationImpact="None."
  local check="$id - $desc"
  local testCategory="Docker Configuration"
  starttestjson "$id" "$desc"

  logbenchjson "NOTE"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
}

check_1_2_2() {
  local id="1.2.2"
  local desc="Ensure that the version of Docker is up to date (Manual)"
  local remediation="You should monitor versions of Docker releases and make sure your software is updated as required."
  local remediationImpact="You should perform a risk assessment regarding Docker version updates and review how they may impact your operations."
  local testCategory="Docker Configuration"
  local check="$id - $desc"
  starttestjson "$id" "$desc"

  docker_version=$(docker version | grep -i -A2 '^server' | grep ' Version:' \
    | awk '{print $NF; exit}' | tr -d '[:alpha:]-,')
  docker_current_version="$(date +%y.%m.0 -d @$(( $(date +%s) - 2592000)))"
  do_version_check "$docker_current_version" "$docker_version"
  if [ $? -eq 11 ]; then
    logbenchjson "INFO"  $id "$testCategory" "$desc" " ** Using $docker_version, verify is it up to date as deemed necessary" "$remediation" "$remediationImpact"
    return
  fi
  logbenchjson "PASS"  $id "$testCategory" "$desc" " ** Using $docker_version which is current" "$remediation" "$remediationImpact"
}

check_1_end() {
  endsectionjson
}
