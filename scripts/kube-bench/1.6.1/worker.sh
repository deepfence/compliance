CIS_PROXY_CMD="kube-proxy"
CIS_KUBELET_CMD="kubelet"
df_k8_4_1_1() {
  local id="df_k8_4_1_1"
  local desc="Ensure that the kubelet service file permissions are set to 644 or more restrictive"
  local remediation="Run the below command (based on the file location on your system) on the each worker node. For example, chmod 644 /etc/systemd/system/kubelet.service.d/10-kubeadm.conf"
  local remediationImpact="None."
  local testCategory="Worker File Mode"
  file="/etc/systemd/system/kubelet.service.d/10-kubeadm.conf"
  if [ -f "$file" ]; then
    if [ "$(stat -c %a $file)" -eq 644 -o "$(stat -c %a $file)" -eq 640 -o "$(stat -c %a $file)" -eq 600 -o "$(stat -c %a $file)" -eq 400 ]; then
      logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
    else
      logbenchjson "WARN"  $id "$testCategory" "$desc" "* Wrong permissions for $file" "$remediation" "$remediationImpact"
    fi
  else
    logbenchjson "INFO"  $id "$testCategory" "$desc" "* File not found" "$remediation" "$remediationImpact"
  fi
}

df_k8_4_1_2() {
  local id="df_k8_4_1_2"
  local desc="Ensure that the kubelet service file ownership is set to root:root"
  local remediation="Run the below command (based on the file location on your system) on the each worker node. For example, chown root:root /etc/systemd/system/kubelet.service.d/10-kubeadm.conf"
  local remediationImpact="None."
  local testCategory="Worker File Mode"
  file="/etc/systemd/system/kubelet.service.d/10-kubeadm.conf"
  if [ -f "$file" ]; then
    if [ "$(stat -c %u%g $file)" -eq 00 ]; then
      logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
    else
      logbenchjson "WARN"  $id "$testCategory" "$desc" "* Wrong ownership for $file" "$remediation" "$remediationImpact"
    fi
  else
    logbenchjson "INFO"  $id "$testCategory" "$desc" "* File not found" "$remediation" "$remediationImpact"
  fi
}


df_k8_4_1_3() {
  local id="df_k8_4_1_3"
  local desc=" Ensure that the proxy kubeconfig file permissions are set to 644 or more restrictive"
  local remediation="Run the below command (based on the file location on your system) on the each worker node. For example, chmod 644 <proxy kubeconfig file"
  local remediationImpact="None."
  local testCategory="Worker File Mode"
  file=""
  if check_argument "$CIS_PROXY_CMD" '--kubeconfig' >/dev/null 2>&1; then
      file=$(get_argument_value "$CIS_PROXY_CMD" '--kubeconfig'|cut -d " " -f 1)
  fi
  file="${pathPrefix}${file}"

  if [ -f "$file" ]; then
    if [ "$(stat -c %a $file)" -eq 644 -o "$(stat -c %a $file)" -eq 600 -o "$(stat -c %a $file)" -eq 400 ]; then
      logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
    else
      logbenchjson "WARN"  $id "$testCategory" "$desc" "* Wrong ownership for $file" "$remediation" "$remediationImpact"
    fi
  else
    logbenchjson "INFO"  $id "$testCategory" "$desc" "* kubeconfig File not found" "$remediation" "$remediationImpact"
  fi
}

df_k8_4_1_4() {
  local id="df_k8_4_1_4"
  local desc="  Ensure that the proxy kubeconfig file ownership is set to root:root"
  local remediation="Run the below command (based on the file location on your system) on the each worker node. For example, chown root:root <proxy kubeconfig file>"
  local remediationImpact="None."
  local testCategory="Worker File Mode"
  if [ -f "$file" ]; then
    if [ "$(stat -c %u%g $file)" -eq 00 ]; then
      logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
    else
      logbenchjson "WARN"  $id "$testCategory" "$desc" "* Wrong ownership for $file" "$remediation" "$remediationImpact"
    fi
  else
    logbenchjson "INFO"  $id "$testCategory" "$desc" "* kubeconfig File not found" "$remediation" "$remediationImpact"
  fi
}


df_k8_4_1_5() {
  local id="df_k8_4_1_5"
  local desc="Ensure that the kubelet.conf file permissions are set to 644 or more restrictive"
  local remediation="Run the below command (based on the file location on your system) on the each worker node. For example, chmod 644 /etc/kubernetes/kubelet.conf"
  local remediationImpact="None."
  local testCategory="Worker File Mode"
  if [ -f "${pathPrefix}/var/lib/kube-proxy/kubeconfig" ]; then
      # kops
      file="${pathPrefix}/var/lib/kube-proxy/kubeconfig"
  else
      file="${pathPrefix}/etc/kubernetes/proxy"
  fi

  if [ -f "$file" ]; then
    if [ "$(stat -c %a $file)" -eq 644 -o "$(stat -c %a $file)" -eq 600 -o "$(stat -c %a $file)" -eq 400 ]; then
      logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
    else
      logbenchjson "WARN"  $id "$testCategory" "$desc" "* Wrong permissions for $file" "$remediation" "$remediationImpact"
    fi
  else
    logbenchjson "INFO"  $id "$testCategory" "$desc" "*  File not found" "$remediation" "$remediationImpact"
  fi
}


df_k8_4_1_6() {
  local id="df_k8_4_1_6"
  local desc="Ensure that the kubelet.conf file ownership is set to root:root"
  local remediation="Run the below command (based on the file location on your system) on the each worker node. For example, chown root:root /etc/kubernetes/kubelet.conf"
  local remediationImpact="None."
  local testCategory="Worker File Mode"
  if [ -f "$file" ]; then
    if [ "$(stat -c %u%g $file)" -eq 00 ]; then
      logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
    else
      logbenchjson "WARN"  $id "$testCategory" "$desc" "* Wrong ownership for $file" "$remediation" "$remediationImpact"
    fi
  else
    logbenchjson "INFO"  $id "$testCategory" "$desc" "*  File not found $file" "$remediation" "$remediationImpact"
  fi
}


df_k8_4_1_7() {
  local id="df_k8_4_1_7"
  local desc="Ensure that the certificate authorities file permissions are set to 644 or more restrictive"
  local remediation="Ensure that the certificate authorities file permissions are set to 644 or more restrictive"
  local remediationImpact="None."
  local testCategory="Worker File Mode"
  if check_argument "$CIS_KUBELET_CMD" '--client-ca-file' >/dev/null 2>&1; then
    file="${pathPrefix}$(get_argument_value "$CIS_KUBELET_CMD" '--client-ca-file')"
    if [ "$(stat -c %a $file)" -eq 644 -o "$(stat -c %a $file)" -eq 600 -o "$(stat -c %a $file)" -eq 400 ]; then
      logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
    else
      logbenchjson "WARN"  $id "$testCategory" "$desc" "* Wrong permissions for $file" "$remediation" "$remediationImpact"
    fi
  else
    logbenchjson "INFO"  $id "$testCategory" "$desc" "*  --client-ca-file not set $file" "$remediation" "$remediationImpact"
  fi
}

df_k8_4_1_8() {
  local id="df_k8_4_1_8"
  local desc="Ensure that the client certificate authorities file ownership is set to root:root"
  local remediation="Run the following command to modify the ownership of the --client-ca-file. chown root:root <filename>"
  local remediationImpact="None."
  local testCategory="Worker File Mode"
  if check_argument "$CIS_KUBELET_CMD" '--client-ca-file' >/dev/null 2>&1; then
    file="${CIS_KUBELET_CMD}$(get_argument_value "$CIS_KUBELET_CMD" '--client-ca-file')"
    if [ "$(stat -c %u%g $file)" -eq 00 ]; then
      logbenchjson "PASS"  $id "$testCategory" "$desc" "* client-ca-file: $file" "$remediation" "$remediationImpact"
    else
      logbenchjson "WARN"  $id "$testCategory" "$desc" "* Wrong ownership for $file" "$remediation" "$remediationImpact"
    fi
  else
    logbenchjson "INFO"  $id "$testCategory" "$desc" "*  --client-ca-file not set $file" "$remediation" "$remediationImpact"
  fi
}

df_k8_4_1_9() {
  local id="df_k8_4_1_9"
  local desc="Ensure that the kubelet configuration file has permissions set to 644 or more restrictive"
  local remediation="Run the following command (using the config file location identied in the Audit step) chmod 644 /var/lib/kubelet/config.yaml"
  local remediationImpact="None."
  local testCategory="Worker File Mode"
  if check_argument "$CIS_KUBELET_CMD" '--config' >/dev/null 2>&1; then
    file="${pathPrefix}$(get_argument_value "$CIS_KUBELET_CMD" '--config')"
    if [ "$(stat -c %a $file)" -eq 644 -o "$(stat -c %a $file)" -eq 600 -o "$(stat -c %a $file)" -eq 400 ]; then
      logbenchjson "PASS"  $id "$testCategory" "$desc" "* kubelet configuration file: $file" "$remediation" "$remediationImpact"
    else
      logbenchjson "WARN"  $id "$testCategory" "$desc" "* Wrong ownership for $file" "$remediation" "$remediationImpact"
    fi
  else
    logbenchjson "INFO"  $id "$testCategory" "$desc" "* kubelet configuration file not set $file" "$remediation" "$remediationImpact"
  fi
}

df_k8_4_1_10() {
  local id="df_k8_4_1_10"
  local desc="Ensure that the kubelet configuration file ownership is set to root:root"
  local remediation="Run the following command (using the config file location identied in the Audit step) chown root:root /etc/kubernetes/kubelet.conf"
  local remediationImpact="None."
  local testCategory="Worker File Mode"
  if check_argument "$CIS_KUBELET_CMD" '--config' >/dev/null 2>&1; then
    file=$(get_argument_value "$CIS_KUBELET_CMD" '--config')
    if [ "$(stat -c %u%g $file)" -eq 00 ]; then
      logbenchjson "PASS"  $id "$testCategory" "$desc" "* kubelet configuration file: $file" "$remediation" "$remediationImpact"
    else
      logbenchjson "WARN"  $id "$testCategory" "$desc" "* Wrong ownership for $file" "$remediation" "$remediationImpact"
    fi
  else
    logbenchjson "INFO"  $id "$testCategory" "$desc" "* kubelet configuration file not set $file" "$remediation" "$remediationImpact"
  fi
}
