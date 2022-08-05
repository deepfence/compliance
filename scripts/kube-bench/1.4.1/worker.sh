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