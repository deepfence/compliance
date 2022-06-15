df_k8_1_1_1() {
  local id="df_k8_1_1_1"
  local desc="Ensure that the API server pod specification file permissions are set to 644 or more restrictive (Automated)"
  local remediation="Run the below command (based on the file location on your system) on the master node. For example, chmod 644 /etc/kubernetes/manifests/kube-apiserver.yaml"
  local remediationImpact="None."
  local testCategory="Master File Mode"
  if [ -f "/etc/kubernetes/manifests/kube-apiserver.manifest" ]; then
      # kops
      file="/etc/kubernetes/manifests/kube-apiserver.manifest"
  else
      file="/etc/kubernetes/manifests/kube-apiserver.yaml"
  fi
  if [ -f $file ]; then
    if [ "$(stat -c %a $file)" -eq 644 -o "$(stat -c %a $file)" -eq 640 -o "$(stat -c %a $file)" -eq 600 ]; then
      logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
    else
      logbenchjson "WARN"  $id "$testCategory" "$desc" "* Wrong permissions for $file" "$remediation" "$remediationImpact"
    fi
  else
    logbenchjson "INFO"  $id "$testCategory" "$desc" "* File not found" "$remediation" "$remediationImpact"
  fi
}

df_k8_1_1_2() {
  local id="df_k8_1_1_2"
  local desc="Ensure that the API server pod specification file ownership is set to root:root"
  local remediation="Run the below command (based on the file location on your system) on the master node. For example, chown root:root /etc/kubernetes/manifests/kube-apiserver.yaml"
  local remediationImpact="None."
  local testCategory="Master File Mode"
  if [ -f "/etc/kubernetes/manifests/kube-apiserver.manifest" ]; then
      # kops
      file="/etc/kubernetes/manifests/kube-apiserver.manifest"
  else
      file="/etc/kubernetes/manifests/kube-apiserver.yaml"
  fi
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

df_k8_1_1_3() {
  local id="df_k8_1_1_3"
  local desc="Ensure that the controller manager pod specification file permissions are set to 644 or more restrictive"
  local remediation="Run the below command (based on the file location on your system) on the master node. For example, chmod 644 /etc/kubernetes/manifests/kube-controller-manager.yaml"
  local remediationImpact="None."
  local testCategory="Master File Mode"
  if [ -f "/etc/kubernetes/manifests/kube-controller-manager.manifest" ]; then
      # kops
      file="/etc/kubernetes/manifests/kube-controller-manager.manifest"
  else
      file="/etc/kubernetes/manifests/kube-controller-manager.yaml"
  fi
  if [ -f $file ]; then
    if [ "$(stat -c %a $file)" -eq 644 -o "$(stat -c %a $file)" -eq 640 -o "$(stat -c %a $file)" -eq 600 ]; then
      logbenchjson "PASS"  $id "$testCategory" "$desc" "" "$remediation" "$remediationImpact"
    else
      logbenchjson "WARN"  $id "$testCategory" "$desc" "* Wrong permissions for $file" "$remediation" "$remediationImpact"
    fi
  else
    logbenchjson "INFO"  $id "$testCategory" "$desc" "* File not found" "$remediation" "$remediationImpact"
  fi
}