#!/bin/sh

if [ -n "$nocolor" ] && [ "$nocolor" = "nocolor" ]; then
  bldred=''
  bldgrn=''
  bldblu=''
  bldylw=''
  bldcyn=''
  bldgry=''
  txtrst=''
else
  bldred='\033[1;31m'
  bldgrn='\033[1;32m'
  bldblu='\033[1;34m'
  bldylw='\033[1;33m'
  bldcyn='\033[1;36m'
  bldgry='\033[1;37m'
  txtrst='\033[0m'
fi

level2="1.3.6, 2.7, 3.1.1, 3.2.2, 4.2.9, 5.2.6, 5.2.9, 5.3.2, 5.4.2, 5.5.1, 5.6.2, 5.6.3, 5.6.4"

info () {

  s_txt=""
  if echo "$1" | grep -q "(Manual)"; then
    s_txt="${bldcyn}[Manual]${txtrst}"
  elif echo "$1" | grep -q "(Automated)"; then
    s_txt="${bldcyn}[Automated]${txtrst}"
  elif echo "$1" | grep -q "(Scored)"; then
    s_txt="${bldcyn}[Scored]${txtrst}"
  elif echo "$1" | grep -q "(Not Scored)"; then
    s_txt="${bldcyn}[Not Scored]${txtrst}"
  fi

  level_txt=""
  if [ ${#s_txt} -ne 0 ]; then
    idx=$(echo "$1" | cut -d " " -f 1)
    if echo "$level2" | grep -q "\<${idx}\>"; then
      level_txt="${bldgry}[Level 2]${txtrst}"
    else
      level_txt="${bldgry}[Level 1]${txtrst}"
    fi
  fi

  printf "%b\n" "${bldblu}[INFO]${txtrst}${level_txt}${s_txt} $1"
}

pass () {

  s_txt=""
  if echo "$1" | grep -q "(Manual)"; then
    s_txt="${bldcyn}[Manual]${txtrst}"
  elif echo "$1" | grep -q "(Automated)"; then
    s_txt="${bldcyn}[Automated]${txtrst}"
  elif echo "$1" | grep -q "(Scored)"; then
    s_txt="${bldcyn}[Scored]${txtrst}"
  elif echo "$1" | grep -q "(Not Scored)"; then
    s_txt="${bldcyn}[Not Scored]${txtrst}"
  fi

  level_txt=""
  if [ ${#s_txt} -ne 0 ]; then
    idx=$(echo "$1" | cut -d " " -f 1)
    if echo "$level2" | grep -q "\<${idx}\>"; then
      level_txt="${bldgry}[Level 2]${txtrst}"
    else
      level_txt="${bldgry}[Level 1]${txtrst}"
    fi
  fi

  printf "%b\n" "${bldgrn}[PASS]${txtrst}${level_txt}${s_txt} $1"

}

warn () {
  s_txt=""
  if echo "$1" | grep -q "(Manual)"; then
    s_txt="${bldcyn}[Manual]${txtrst}"
  elif echo "$1" | grep -q "(Automated)"; then
    s_txt="${bldcyn}[Automated]${txtrst}"
  elif echo "$1" | grep -q "(Scored)"; then
    s_txt="${bldcyn}[Scored]${txtrst}"
  elif echo "$1" | grep -q "(Not Scored)"; then
    s_txt="${bldcyn}[Not Scored]${txtrst}"
  fi

  level_txt=""
  if [ ${#s_txt} -ne 0 ]; then
    idx=$(echo "$1" | cut -d " " -f 1)
    if echo "$level2" | grep -q "\<${idx}\>"; then
      level_txt="${bldgry}[Level 2]${txtrst}"
    else
      level_txt="${bldgry}[Level 1]${txtrst}"
    fi
  fi

  printf "%b\n" "${bldred}[WARN]${txtrst}${level_txt}${s_txt} $1"

}

yell () {
  printf "%b\n" "${bldylw}$1${txtrst}\n"
}

yell "# ------------------------------------------------------------------------------
# Kubernetes CIS benchmark
#
# NeuVector, Inc. (c) 2020-
#
# NeuVector delivers an application and network intelligent container security
# solution that automatically adapts to protect running containers. Don’t let
# security concerns slow down your CI/CD processes.
# ------------------------------------------------------------------------------"

#get a process command line from /proc
get_command_line_args() {
    PROC="$1"
    len=${#PROC}
    if [ $len -gt 15 ]; then
		ps aux|grep  "$CMD "|grep -v "grep" |sed "s/.*$CMD \(.*\)/\1/g"
    else
        for PID in $(pgrep -n "$PROC")
        do
            tr "\0" " " < /proc/"$PID"/cmdline
        done
    fi
}

#get an argument value from command line
get_argument_value() {
    CMD="$1"
    OPTION="$2"

    get_command_line_args "$CMD" |
    sed \
        -e 's/\-\-/\n--/g' \
        |
    grep "^${OPTION}" |
    sed \
        -e "s/^${OPTION}=//g"
}

#check whether an argument exist in command line
check_argument() {
    CMD="$1"
    OPTION="$2"

    get_command_line_args "$CMD" |
    sed \
        -e 's/\-\-/\n--/g' \
        |
    grep "^${OPTION}"
}

info "1 - Control Plane Components"

info "1.1 - Master Node Configuration Files"

check_1_1_1="1.1.1  - Ensure that the API server pod specification file permissions are set to 644 or more restrictive (Manual)"

file="/etc/kubernetes/manifests/kube-apiserver-pod.yaml"
if [ -f $file ]; then
  if [ "$(stat -c %a $file)" -eq 644 -o "$(stat -c %a $file)" -eq 640 -o "$(stat -c %a $file)" -eq 600 ]; then
    pass "$check_1_1_1"
  else
    warn "$check_1_1_1"
    warn "     * Wrong permissions for $file"
  fi
else
  info "$check_1_1_1"
  info "     * File not found"
fi

check_1_1_2="1.1.2  - Ensure that the API server pod specification file ownership is set to root:root (Manual)"

file="/etc/kubernetes/manifests/kube-apiserver-pod.yaml"
if [ -f "$file" ]; then
  if [ "$(stat -c %u%g $file)" -eq 00 ]; then
    pass "$check_1_1_2"
  else
    warn "$check_1_1_2"
    warn "     * Wrong ownership for $file"
  fi
else
  info "$check_1_1_2"
fi

check_1_1_3="1.1.3  - Ensure that the controller manager pod specification file permissions are set to 644 or more restrictive (Manual)"

file="/etc/kubernetes/manifests/kube-controller-manager-pod.yaml"
if [ -f "$file" ]; then
  if [ "$(stat -c %a $file)" -eq 644 -o "$(stat -c %a $file)" -eq 600 -o "$(stat -c %a $file)" -eq 400 ]; then
    pass "$check_1_1_3"
  else
    warn "$check_1_1_3"
    warn "     * Wrong permissions for $file"
  fi
else
  info "$check_1_1_3"
  info "     * File not found"
fi

check_1_1_4="1.1.4  - Ensure that the controller manager pod specification file ownership is set to root:root (Manual)"

file="/etc/kubernetes/manifests/kube-controller-manager-pod.yaml"
if [ -f "$file" ]; then
  if [ "$(stat -c %u%g $file)" -eq 00 ]; then
    pass "$check_1_1_4"
  else
    warn "$check_1_1_4"
    warn "     * Wrong ownership for $file"
  fi
else
  info "$check_1_1_4"
fi

check_1_1_5="1.1.5  - Ensure that the scheduler pod specification file permissions are set to 644 or more restrictive (Manual)"

file="/etc/kubernetes/manifests/kube-scheduler-pod.yaml"
if [ -f "$file" ]; then
  if [ "$(stat -c %a $file)" -eq 644 -o "$(stat -c %a $file)" -eq 600 -o "$(stat -c %a $file)" -eq 400 ]; then
    pass "$check_1_1_5"
  else
    warn "$check_1_1_5"
    warn "     * Wrong permissions for $file"
  fi
else
  info "$check_1_1_5"
  info "     * File not found"
fi

check_1_1_6="1.1.6  - Ensure that the scheduler pod specification file ownership is set to root:root (Manual)"

file="/etc/kubernetes/manifests/kube-scheduler-pod.yaml"
if [ -f "$file" ]; then
  if [ "$(stat -c %u%g $file)" -eq 00 ]; then
    pass "$check_1_1_6"
  else
    warn "$check_1_1_6"
    warn "     * Wrong ownership for $file"
  fi
else
  info "$check_1_1_6"
fi

#todo file name changes to "etcd-pod"
check_1_1_7="1.1.7  - Ensure that the etcd pod specification file permissions are set to 644 or more restrictive (Manual)"

file="/etc/kubernetes/manifests/etcd-pod.yaml"
if [ -f "$file" ]; then
  if [ "$(stat -c %a $file)" -eq 644 -o "$(stat -c %a $file)" -eq 600 -o "$(stat -c %a $file)" -eq 400 ]; then
    pass "$check_1_1_7"
  else
    warn "$check_1_1_7"
    warn "     * Wrong permissions for $file"
  fi
else
  info "$check_1_1_7"
  info "     * File not found"
fi

check_1_1_8="1.1.8  - Ensure that the etcd pod specification file ownership is set to root:root (Manual)"

file="/etc/kubernetes/manifests/etcd-pod.yaml"
if [ -f "$file" ]; then
  if [ "$(stat -c %u%g $file)" -eq 00 ]; then
    pass "$check_1_1_8"
  else
    warn "$check_1_1_8"
    warn "     * Wrong ownership for $file"
  fi
else
  info "$check_1_1_8"
fi

check_1_1_9="1.1.9  - Ensure that the Container Network Interface file permissions are set to 644 or more restrictive (Manual)"

valid_permission=true
path_cni_netd="/etc/cni/net.d"
path_cni_bin="/opt/cni/bin"
path_cni_multus="/var/run/multus/cni/net.d"
path_sdn_lib_ocpsdn="/var/lib/cni/networks/openshift-sdn"
path_sdn_run_ocpsdn="/var/run/openshift-sdn"
path_ovs_openv="/var/run/openvswitch"
path_ovs_k8s="/var/run/kubernetes"
path_ovs_etc_openv="/etc/openvswitch"
path_ovs_run_openv="/run/openvswitch"
path_ovs_var_openv="/var/run/openvswitch"

invalid_file_list=""

for p in "$path_cni_netd" "$path_cni_bin" "$path_cni_multus" "$path_sdn_lib_ocpsdn" "$path_sdn_run_ocpsdn" "$path_ovs_openv" "$path_ovs_k8s" "$path_ovs_etc_openv" "$path_ovs_run_openv" "$path_ovs_var_openv"
do
  if [ -d "$p" ]; then
    files=$(find $p -type f)
    for i in $files
    do
      if [ $(stat -c %a "$i") -gt 644 ]; then
        valid_permission=false
        invalid_file_list+=" $i"
      fi
    done
  fi
done

if [ "$valid_permission" = "true" ]; then
  pass "$check_1_1_9"
else
  warn "$check_1_1_9"
  for p in $invalid_file_list
  do
    warn " *Wrong ownership for $p "
  done
fi

check_1_1_10="1.1.10  - Ensure that the Container Network Interface file ownership is set to root:root (Manual)"

valid_ownership=true
path_cni_netd="/etc/cni/net.d"
path_cni_bin="/opt/cni/bin"
path_cni_multus="/var/run/multus/cni/net.d"

path_sdn_lib_ocpsdn="/var/lib/cni/networks/openshift-sdn"
path_sdn_run_ocpsdn="/var/run/openshift-sdn"

path_ovs_openv="/var/run/openvswitch"
path_ovs_k8s="/var/run/kubernetes"
path_ovs_etc_openv="/etc/openvswitch"
path_ovs_run_openv="/run/openvswitch"
path_ovs_var_openv="/var/run/openvswitch"

invalid_file_list=""

for p in "$path_cni_netd" "$path_cni_bin" "$path_cni_multus" "$path_sdn_lib_ocpsdn" "$path_sdn_run_ocpsdn"
do
  if [ -d "$p" ]; then
    files=$(find $p -type f)
    for i in $files
    do
      if [ $(stat -c %U:%G "$i") != "root:root" ]; then
        valid_ownership=false
        invalid_file_list+=" $i"
      fi
    done
  fi
done

for p in "$path_ovs_openv" "$path_ovs_k8s" "$path_ovs_etc_openv" "$path_ovs_run_openv" "$path_ovs_var_openv"
do
  if [ -d "$p" ]; then
    files=$(find $p -type f)
    for i in $files
    do
      if [ $(stat -c %U:%G "$i") != "openvswitch:openvswitch" ]; then
        valid_ownership=false
        invalid_file_list+=" $i"
      fi
    done
  fi
done

if [ "$valid_ownership" = "true" ]; then
  pass "$check_1_1_10"
else
  warn "$check_1_1_10"
  for p in $invalid_file_list
  do
    warn " *Wrong ownership for $p "
  done
fi

check_1_1_11="1.1.11  - Ensure that the etcd data directory permissions are set to 700 or more restrictive (Manual)"

file="/var/lib/etcd"
if [ -d "$file" ]; then
  if [ "$(stat -c %a $file)" -eq 700 ]; then
    pass "$check_1_1_11"
  else
    warn "$check_1_1_11"
    warn "     * Wrong permission for $file"
  fi
else
  info "$check_1_1_11"
fi

#todo review
check_1_1_12="1.1.12  - Ensure that the etcd data directory ownership is set to root:root (Manual)"

file="/var/lib/etcd"
if [ -d "$file" ]; then
  if [ "$(stat -c %u%g $file)" -eq 00 ]; then
    pass "$check_1_1_12"
  else
    warn "$check_1_1_12"
    warn "     * Wrong ownership for $file"
  fi
else
  info "$check_1_1_12"
fi

check_1_1_13="1.1.13  - Ensure that the admin.conf file permissions are set to 644 or more restrictive (Manual)"

file="/etc/kubernetes/kubeconfig"
if [ -f "$file" ]; then
  if [ "$(stat -c %a $file)" -le 644 ]; then
    pass "$check_1_1_13"
  else
    warn "$check_1_1_13"
    warn "     * Wrong permissions for $file"
  fi
else
  info "$check_1_1_13"
  info "     * File not found"
fi

check_1_1_14="1.1.14  - Ensure that the admin.conf file ownership is set to root:root (Manual)"

file="/etc/kubernetes/kubeconfig"
if [ -f "$file" ]; then
  if [ "$(stat -c %u%g $file)" -eq 00 ]; then
    pass "$check_1_1_14"
  else
    warn "$check_1_1_14"
    warn "     * Wrong ownership for $file"
  fi
else
  info "$check_1_1_14"
fi

check_1_1_15="1.1.15  - Ensure that the scheduler.conf file permissions are set to 644 or more restrictive (Manual)"

files=$(find /etc/kubernetes/static-pod-resources -type f -wholename '*/configmaps/scheduler-kubeconfig/kubeconfig')

valid_permission=false
for i in $files
do
  if [ $(stat -c %a "$i") -eq 644 -o $(stat -c %a "$i") -eq 600 -o $(stat -c %a "$i") -eq 400 ]; then
    valid_permission=true
  else
    valid_permission=false
    break
  fi
done

if [ "$valid_permission" = "true" ]; then
  pass "$check_1_1_15"
else
  warn "$check_1_1_15"
fi

check_1_1_16="1.1.16  - Ensure that the scheduler.conf file ownership is set to root:root (Manual)"

files=$(find /etc/kubernetes/static-pod-resources -type f -wholename '*/configmaps/scheduler-kubeconfig/kubeconfig')

valid_permission=false
for i in $files
do
  if [ $(stat -c %u%g "$i") -eq 00 ]; then
    valid_permission=true
  else
    valid_permission=false
    break
  fi
done

if [ "$valid_permission" = "true" ]; then
  pass "$check_1_1_16"
else
  warn "$check_1_1_16"
fi

check_1_1_17="1.1.17  - Ensure that the controller-manager.conf file permissions are set to 644 or more restrictive (Manual)"

files=$(find /etc/kubernetes/static-pod-resources -type f -wholename '*/configmaps/controller-manager-kubeconfig/kubeconfig')

valid_permission=false
for i in $files
do
  if [ $(stat -c %a "$i") -eq 644 -o $(stat -c %a "$i") -eq 600 -o $(stat -c %a "$i") -eq 400 ]; then
    valid_permission=true
  else
    valid_permission=false
    break
  fi
done

if [ "$valid_permission" = "true" ]; then
  pass "$check_1_1_17"
else
  warn "$check_1_1_17"
fi

check_1_1_18="1.1.18  - Ensure that the controller-manager.conf file ownership is set to root:root (Manual)"

files=$(find /etc/kubernetes/static-pod-resources -type f -wholename '*/configmaps/controller-manager-kubeconfig/kubeconfig')

valid_permission=false
for i in $files
do
  if [ $(stat -c %u%g "$i") -eq 00 ]; then
    valid_permission=true
  else
    valid_permission=false
    break
  fi
done

if [ "$valid_permission" = "true" ]; then
  pass "$check_1_1_18"
else
  warn "$check_1_1_18"
fi

check_1_1_19="1.1.19  - Ensure that the Kubernetes PKI directory and file ownership is set to root:root (Manual)"

cert_path="/etc/kubernetes/static-pod-certs"
valid_perm_dir=false
valid_perm_file=false

if [ -f "$cert_path" ]; then

  directories=$(find $cert_path -type d -wholename '*/secrets*')
  files=$(find $cert_path -type f -wholename '*/secrets*')

  for i in $directories
  do
    if [ $(stat -c %u%g "$i") -eq 00 ]; then
      valid_perm_dir=true
    else
      valid_perm_dir=false
      break
    fi
  done

  for i in $files
  do
    if [ $(stat -c %u%g "$i") -eq 00 ]; then
      valid_perm_file=true
    else
      valid_perm_file=false
      break
    fi
  done

  if [ "$valid_perm_file" = "true" ] && [ "$valid_perm_dir" = "true" ]; then
    pass "$check_1_1_19"
  else
    warn "$check_1_1_19"
  fi
else
   warn "$check_1_1_19"
   warn "$cert_path doesn't exist."
fi

check_1_1_20="1.1.20  - Ensure that the Kubernetes PKI certificate file permissions are set to 644 or more restrictive (Manual)"

cert_path="/etc/kubernetes/static-pod-certs"
if [ -f "$cert_path" ]; then
  files=$(find $cert_path -type f -wholename '*/secrets/*.crt')
  valid_perm_file=false
  for i in $files
  do
    if [ $(stat -c %a "$i") -eq 600 ]; then
      valid_perm_file=true
    else
      valid_perm_file=false
      break
    fi
  done

  if [ "$valid_perm_file" = "true" ]; then
    pass "$check_1_1_20"
  else
    warn "$check_1_1_20"
  fi
else
   warn "$check_1_1_20"
   warn "$cert_path doesn't exist."
fi

check_1_1_21="1.1.21  - Ensure that the Kubernetes PKI key file permissions are set to 600 (Manual)"

cert_path="/etc/kubernetes/static-pod-certs"

if [ -f "$cert_path" ]; then
  files=$(find $cert_path -type f -wholename '*/secrets/*.key')
  valid_perm_file=false
  for i in $files
  do
    if [ $(stat -c %a "$i") -eq 600 ]; then
      valid_perm_file=true
    else
      valid_perm_file=false
      break
    fi
  done

  if [ "$valid_perm_file" = "true" ]; then
    pass "$check_1_1_21"
  else
    warn "$check_1_1_21"
  fi
else
   warn "$check_1_1_21"
   warn "$cert_path doesn't exist."
fi

info "1.2 - API Server"

#todo oc
check_1_2_1="1.2.1  - Ensure that anonymous requests are authorized (Manual)"
output_kube=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-apiserver/configmaps/config | \
  jq -r '.data["config.yaml"]' | \
  jq '.auditConfig.policyConfiguration.rules' | \
  grep 'system:unauthenticated' )
output=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-apiserver/configmaps/config | \
  jq -r '.data["config.yaml"]' | \
  jq '.auditConfig.policyConfiguration.rules' | \
  grep 'system:unauthenticated' )

if [ -z "$output_kube" ] || [ -z "$output" ]; then
  warn "$check_1_2_1"
else
  pass "$check_1_2_1"
fi

check_1_2_2="1.2.2  - Ensure that the --basic-auth-file argument is not set (Manual)"
output_ocp=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-apiserver/configmaps/config | grep --color "basic-auth")
output_api=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-apiserver/configmaps/config | grep --color "basic-auth" )
running=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/apis/config.openshift.io/v1/clusteroperators/authentication )
if [ -z "$output_ocp" ] && [ -z "$output_api" ] && [ -n "$running" ] ; then
  pass "$check_1_2_2"
else
  warn "$check_1_2_2"
fi

check_1_2_3="1.2.3  - Ensure that the --token-auth-file parameter is not set (Manual)"
output_1=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-apiserver/configmaps/config | jq -r '.data["config.yaml"]' | jq '.apiServerArguments //empty')
output_2=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/apis/operator.openshift.io/v1/kubeapiservers/cluster | jq '.spec.observedConfig.apiServerArguments //empty')
output_3=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-apiserver/configmaps/config | jq -r '.data["config.yaml"]' | jq '.apiServerArguments //empty')
output_4=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/apis/config.openshift.io/v1/clusteroperators/authentication)
if [ -z "$output_1" ] || [ -z "$output_2" ] || [ -z "$output_3" ] || [ -z "$output_4" ]; then
  warn "$check_1_2_3"
else
  pass "$check_1_2_3"
fi

check_1_2_4="1.2.4  - Use https for kubelet connections (Manual)"
output_1=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-apiserver/configmaps/config | jq -r '.data["config.yaml"]' | jq '.kubeletClientInfo //empty' )
output_2=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-apiserver/secrets/serving-cert )
if [ -z "$output_1" ] || [ -z "$output_2" ]; then
  warn "$check_1_2_4"
else
  pass "$check_1_2_4"
fi

check_1_2_5="1.2.5  - Ensure that the kubelet uses certificates to authenticate (Manual)"
output=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-apiserver/configmaps/config | jq -r '.data["config.yaml"]' | jq '.kubeletClientInfo //empty' )
if [ -z "$output" ]; then
  warn "$check_1_2_5"
else
  pass "$check_1_2_5"
fi

check_1_2_6="1.2.6  - Verify that the kubelet certificate authority is set as appropriate (Manual)"
output=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-apiserver/configmaps/config  | jq -r '.data["config.yaml"]' | jq '.kubeletClientInfo //empty' )
if [ -z "$output" ]; then
  warn "$check_1_2_6"
else
  pass "$check_1_2_6"
fi

check_1_2_7="1.2.7  - Ensure that the --authorization-mode argument is not set to AlwaysAllow (Manual)"
output_1=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-apiserver/configmaps/config  | jq -r '.data["config.yaml"]' | jq '.apiServerArguments //empty' )
output_2=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-apiserver/configmaps/config  | jq -r '.data["config.yaml"]' | jq '.apiServerArguments //empty' )
output_3=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/apis/operator.openshift.io/v1/kubeapiservers/cluster | jq '.spec.observedConfig.apiServerArguments //empty' )
if [ -z "$output_1" ] || [ -z "$output_2" ] || [ -z "$output_3" ]; then
  warn "$check_1_2_7"
else
  pass "$check_1_2_7"
fi

check_1_2_8="1.2.8  - Verify that the Node authorizer is enabled (Manual)"
output_1=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-apiserver/configmaps/config | jq -r '.data["config.yaml"]' | jq '.apiServerArguments //empty' )
output_2=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-apiserver/configmaps/config | jq -r '.data["config.yaml"]' | jq '.apiServerArguments //empty' )
output_3=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/apis/operator.openshift.io/v1/kubeapiservers/cluster | jq '.spec.observedConfig.apiServerArguments //empty' )
if [ -z "$output_1" ] || [ -z "$output_2" ] || [ -z "$output_3" ]; then
  warn "$check_1_2_8"
else
  pass "$check_1_2_8"
fi

check_1_2_9="1.2.9  - Verify that RBAC is enabled (Manual)"
output_1=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-apiserver/configmaps/config | jq -r '.data["config.yaml"]' | jq '.apiServerArguments //empty' )
output_2=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-apiserver/configmaps/config | jq -r '.data["config.yaml"]' | jq '.apiServerArguments //empty' )
if [ -z "$output_1" ] || [ -z "$output_2" ]; then
  warn "$check_1_2_9"
else
  pass "$check_1_2_9"
fi

check_1_2_10="1.2.10  - Ensure that the APIPriorityAndFairness feature gate is enabled (Manual)"
output_1=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-apiserver/configmaps/config | jq -r '.data."config.yaml"' | jq '.apiServerArguments."enable-admission-plugins" //empty')
output_2=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/apis/operator.openshift.io/v1/kubeapiservers/cluster | jq -r '.spec.unsupportedConfigOverrides //empty')
if [ -z "$output_1" ] && [ -z "$output_2" ]; then
    pass "$check_1_2_10"
else
    warn "$check_1_2_10"
fi

check_1_2_11="1.2.11  - Ensure that the admission control plugin AlwaysAdmit is not set (Manual)"
output_1=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-apiserver/configmaps/config | jq -r '.data."config.yaml"' | jq '.apiServerArguments."enable-admission-plugins" //empty')
output_2=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/apis/operator.openshift.io/v1/kubeapiservers/cluster | jq -r '.spec.unsupportedConfigOverrides //empty')
if [ -z "$output_1" ] && [ -z "$output_2" ]; then
    pass "$check_1_2_11"
else
    warn "$check_1_2_11"
fi

check_1_2_12="1.2.12  - Ensure that the admission control plugin AlwaysPullImages is set (Manual)"
output_1=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-apiserver/configmaps/config | jq -r '.data."config.yaml"' | jq '.apiServerArguments."enable-admission-plugins" //empty')
output_2=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/apis/operator.openshift.io/v1/kubeapiservers/cluster | jq -r '.spec.unsupportedConfigOverrides //empty')
if [ -z "$output_1" ] && [ -z "$output_2" ]; then
    pass "$check_1_2_12"
else
    warn "$check_1_2_12"
fi

check_1_2_13="1.2.13  - Ensure that the admission control plugin SecurityContextDeny is not set (Manual)"
output_1=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-apiserver/configmaps/config | jq -r '.data."config.yaml"' | jq '.apiServerArguments."enable-admission-plugins" //empty')
output_2=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/apis/operator.openshift.io/v1/kubeapiservers/cluster | jq -r '.spec.unsupportedConfigOverrides //empty')
output_3=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/apis/security.openshift.io/v1/securitycontextconstraints/restricted | grep "SecurityContextDeny")
output_4=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/apis/security.openshift.io/v1/securitycontextconstraints/restricted  | grep 'Allow Privileged:'| grep false)
if [ -z "$output_1" ] && [ -z "$output_2" ] && [ -z "$output_3" ] && [ -n "$output_4" ]; then
    pass "$check_1_2_13"
else
    warn "$check_1_2_13"
fi

check_1_2_14="1.2.14  - Ensure that the admission control plugin ServiceAccount is set (Manual)"
output_1=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-apiserver/configmaps/config | jq -r '.data."config.yaml"' | jq '.apiServerArguments."enable-admission-plugins" //empty')
output_2=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/apis/operator.openshift.io/v1/kubeapiservers/cluster | jq -r '.spec.unsupportedConfigOverrides //empty')
if [ -z "$output_1" ] && [ -z "$output_2" ]; then
    pass "$check_1_2_14"
else
    warn "$check_1_2_14"
fi

#todo review with Andson "Verify that NamespaceLifecycle is in place"
check_1_2_15="1.2.15  - Ensure that the admission control plugin NamespaceLifecycle is set (Manual)"
output_1=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-apiserver/configmaps/config | jq -r '.data."config.yaml"' | jq '.apiServerArguments."enable-admission-plugins" //empty')
output_2=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/apis/operator.openshift.io/v1/kubeapiservers/cluster | jq -r '.spec.unsupportedConfigOverrides //empty')
if [ -z "$output_1" ] && [ -z "$output_2" ]; then
    pass "$check_1_2_15"
else
    warn "$check_1_2_15"
fi

#todo the same audit script as 1.2.13
check_1_2_16="1.2.16  - Ensure that the admission control plugin SecurityContextConstraint is set (Manual)"
output_1=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-apiserver/configmaps/config | jq -r '.data."config.yaml"' | jq '.apiServerArguments."enable-admission-plugins" //empty')
output_2=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/apis/operator.openshift.io/v1/kubeapiservers/cluster | jq -r '.spec.unsupportedConfigOverrides //empty')
output_3=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/apis/security.openshift.io/v1/securitycontextconstraints/restricted | grep "SecurityContextDeny")
output_4=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/apis/security.openshift.io/v1/securitycontextconstraints/restricted | grep 'Allow Privileged:'| grep false)
if [ -z "$output_1" ] && [ -z "$output_2" ] && [ -z "$output_3" ] && [ -n "$output_4" ]; then
    pass "$check_1_2_16"
else
    warn "$check_1_2_16"
fi

#todo reivew with Andson "need a command to verify NodeRestriction"
check_1_2_17="1.2.17  - Ensure that the admission control plugin NodeRestriction is set (Manual)"
output_1=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-apiserver/configmaps/config | jq -r '.data."config.yaml"' | jq '.apiServerArguments."enable-admission-plugins"  //empty')
output_2=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/apis/operator.openshift.io/v1/kubeapiservers/cluster | jq -r '.spec.unsupportedConfigOverrides //empty')
if [ -z "$output_1" ] && [ -z "$output_2" ]; then
    pass "$check_1_2_17"
else
    warn "$check_1_2_17"
fi

check_1_2_18="1.2.18  - Ensure that the --insecure-bind-address argument is not set (Manual)"
output_1=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/apis/operator.openshift.io/v1/kubeapiservers/cluster | jq '.spec.observedConfig' | grep bind)
output_2=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-apiserver/configmaps/kube-apiserver-pod | grep --color "insecure-bind-address")

if [ -n "$output_1" ] && [ -z "$output_2" ]; then
  pass "$check_1_2_18"
else
  warn "$check_1_2_18"
fi

#todo review with Andson "insecure-port"
check_1_2_19="1.2.19  - Ensure that the --insecure-port argument is set to 0 (Manual)"
output_1=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/apis/operator.openshift.io/v1/kubeapiservers/cluster | jq '.spec.observedConfig' | grep insecure)
output_2=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-apiserver/configmaps/kube-apiserver-pod | grep --color "insecure-port")
if [ -z "$output" ] && [ -n "$output_2" ]; then
  pass "$check_1_2_19"
else
  warn "$check_1_2_19"
fi

check_1_2_20="1.2.20  - Ensure that the --secure-port argument is not set to 0 (Manual)"
output_1=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/apis/operator.openshift.io/v1/kubeapiservers/cluster | jq '.spec.observedConfig //empty')
output_2=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-apiserver/configmaps/config | grep --color "bindAddress")
if [ -z "$output_1" ] || [ -z "$output_2" ]; then
  warn "$check_1_2_20"
else
  pass "$check_1_2_20"
fi

#todo review by Andson "default port value 10248, bindAddress is 127.0.0.1"
check_1_2_21="1.2.21  - Ensure that the healthz endpoint is protected by RBAC (Manual)"
output_1=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/apis/operator.openshift.io/v1/kubeapiservers/cluster | jq '.spec.observedConfig.apiServerArguments //empty')
output_2=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-apiserver/configmaps/kube-apiserver-pod | grep --color healthz)
output_3=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-apiserver/endpoints/api)
if [ -n "$output_1" ] && [ -n "$output_2" ] && [ -n "$output_3" ]; then
  pass "$check_1_2_21"
else
  warn "$check_1_2_21"
fi

check_1_2_22="1.2.22  - Ensure that the --audit-log-path argument is set (Manual)"
output_1=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/apis/operator.openshift.io/v1/kubeapiservers/cluster | jq '.spec.observedConfig.apiServerArguments')
output_2=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-apiserver/configmaps/config | jq -r '.data["config.yaml"]' | jq -r '.auditConfig.auditFilePath //empty')
output_3=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-apiserver/configmaps/config | jq -r '.data["config.yaml"]' | jq -r '.auditConfig.auditFilePath //empty')
if [ -z "$output_1" ] || [ -z "$output_2" ] || [ -z "$output_3" ]; then
    warn "$check_1_2_22"
else
    pass "$check_1_2_22"
fi

check_1_2_23="1.2.23  - Ensure that the audit logs are forwarded off the cluster for retention (Manual)"
output_1=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/apis/operator.openshift.io/v1/kubeapiservers/cluster | jq '.spec.observedConfig //empty')
if [ -n "$output_1" ]; then
  pass "$check_1_2_23"
else
  warn "$check_1_2_23"
fi

check_1_2_24="1.2.24  - Ensure that the maximumRetainedFiles argument is set to 10 or as appropriate (Manual)"
output_1=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-apiserver/configmaps/config | jq -r '.data["config.yaml"]' | jq -r '.auditConfig.maximumRetainedFiles //empty')
output_2=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-apiserver/configmaps/config | jq -r '.data["config.yaml"]' | jq -r '.auditConfig.maximumRetainedFiles //empty')
if [ "$output_1" -eq 10 -a "$output_2" -eq 10 ] > /dev/null 2>&1; then
  pass "$check_1_2_24"
else
  warn "$check_1_2_24"
fi

check_1_2_25="1.2.25  - Ensure that the maximumFileSizeMegabytes argument is set to 100 or as appropriate (Manual)"
output_1=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-apiserver/configmaps/config | jq -r '.data["config.yaml"]' | jq -r '.auditConfig.maximumFileSizeMegabytes //empty')
output_2=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-apiserver/configmaps/config | jq -r '.data["config.yaml"]' | jq -r '.auditConfig.maximumFileSizeMegabytes //empty')
if [ "$output_1" -eq 100 -a "$output_2" -eq 100 ] > /dev/null 2>&1; then
  pass "$check_1_2_25"
else
  warn "$check_1_2_25"
fi

check_1_2_26="1.2.26  - Ensure that the --request-timeout argument is set as appropriate (Manual)"
output_1=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-apiserver/configmaps/config | jq -r '.data["config.yaml"]' | jq -r '.servingInfo.requestTimeoutSeconds //empty')
output_2=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-apiserver/configmaps/config | jq -r '.data["config.yaml"]' | jq -r '.servingInfo.requestTimeoutSeconds //empty')
if [ "$output_1" -eq 3600 -a -z "$output_2" ]; then
  pass "$check_1_2_26"
else
  warn "$check_1_2_26"
fi

#todo review with Andson
check_1_2_27="1.2.27  - Ensure that the --service-account-lookup argument is set to true (Manual)"
info "$check_1_2_27
      OpenShift denies access for any OAuth Access token that does not exist in its etcd data store.
      OpenShift does not use the service-account-lookup flag."

check_1_2_28="1.2.28  - Ensure that the --service-account-key-file argument is set as appropriate (Manual)"
output_1=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-apiserver/configmaps/config | jq -r '.data["config.yaml"]' | jq -r '.serviceAccountPublicKeyFiles //empty')
output_2=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-apiserver/configmaps/config | jq -r '.data["config.yaml"]' | jq -r '.serviceAccountPublicKeyFiles //empty')
if [ -z "$output_1" ] || [ -z "$output_2" ]; then
  warn "$check_1_2_28"
else
  pass "$check_1_2_28"
fi

check_1_2_29="1.2.29  - Ensure that the --etcd-certfile and --etcd-keyfile arguments are set as appropriate (Manual)"
output_cert=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-apiserver/configmaps/config | jq -r '.data["config.yaml"]' | jq -r '.storageConfig.certFile //empty')
output_key=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-apiserver/configmaps/config | jq -r '.data["config.yaml"]' | jq -r '.storageConfig.keyFile //empty')
if [ -z "$output_cert" ] || [ -z "$output_key" ]; then
  warn "$check_1_2_29"
else
  pass "$check_1_2_29"
fi

check_1_2_30="1.2.30  - Ensure that the --tls-cert-file and --tls-private-key-file arguments are set as appropriate (Manual)"
output_cert=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-apiserver/configmaps/config | jq -r '.data["config.yaml"]' | jq -r '.servingInfo.certFile //empty')
output_key=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-apiserver/configmaps/config | jq -r '.data["config.yaml"]' | jq -r '.servingInfo.keyFile //empty')
if [ -z "$output_cert" ] || [ -z "$output_key" ]; then
  warn "$check_1_2_30"
else
  pass "$check_1_2_30"
fi

check_1_2_31="1.2.31  - Ensure that the --client-ca-file argument is set as appropriate (Manual)"
output=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-apiserver/configmaps/config | jq -r '.data["config.yaml"]' | jq -r '.servingInfo.clientCA //empty')
if [ -z "$output" ]; then
  warn "$check_1_2_31"
else
  pass "$check_1_2_31"
fi

check_1_2_32="1.2.32  - Ensure that the --etcd-cafile argument is set as appropriate (Manual)"
output=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-apiserver/configmaps/config | jq -r '.data["config.yaml"]' | jq -r '.storageConfig.ca //empty')
if [ -z "$output" ]; then
  warn "$check_1_2_32"
else
  pass "$check_1_2_32"
fi

#todo review with Andson
check_1_2_33="1.2.33  - Ensure that the --encryption-provider-config argument is set as appropriate (Manual)"
output=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/apis/operator.openshift.io/v1/openshiftapiservers/cluster -o=jsonpath='{range .items[0].status.conditions[?(@.type=="Encrypted")]}{.reason}{"\n"}{.message}{"\n"}')
if [ -z "$output" ]; then
  warn "$check_1_2_33"
else
  pass "$check_1_2_33"
fi
#if get_argument_value "$CIS_APISERVER_CMD" '--encryption-provider-config'| grep 'EncryptionConfig' >/dev/null 2>&1; then
#    pass "$check_1_2_33"
#else
#    warn "$check_1_2_33"
#fi

#todo review with Andson
check_1_2_34="1.2.34  - Ensure that encryption providers are appropriately configured (Manual)"
output=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/apis/operator.openshift.io/v1/openshiftapiservers/cluster -o=jsonpath='{range .items[0].status.conditions[?(@.type=="Encrypted")]}{.reason}{"\n"}{.message}{"\n"}')
if [ -z "$output" ]; then
  warn "$check_1_2_34"
else
  pass "$check_1_2_34"
fi
#if check_argument "$CIS_APISERVER_CMD" '--encryption-provider-config' >/dev/null 2>&1; then
#    encryptionConfig=$(get_argument_value "$CIS_APISERVER_CMD" '--encryption-provider-config')
#    if [ -f "$encryptionConfig" ]; then
#      if [ $(grep -c "\- aescbc:\|\- kms:\|\- secretbox:" $encryptionConfig) -ne 0 ]; then
#        pass "$check_1_2_34"
#      else
#        warn "$check_1_2_34"
#      fi
#    else
#      warn "$check_1_2_34"
#    fi
#else
#    warn "$check_1_2_34"
#fi
#if get_argument_value "$CIS_APISERVER_CMD" '--experimental-encryption-provider-config'| grep 'EncryptionConfig' >/dev/null 2>&1; then
#    encryptionConfig=$(get_argument_value "$CIS_APISERVER_CMD" '--experimental-encryption-provider-config')
#    if sed ':a;N;$!ba;s/\n/ /g' $encryptionConfig |grep "providers:\s* - aescbc" >/dev/null 2>&1; then
#        pass "$check_1_2_34"
#    else
#        warn "$check_1_2_34"
#    fi
#else
#    warn "$check_1_2_34"
#fi

#todo review with Andson
check_1_2_35="1.2.35  - Ensure that the API Server only makes use of Strong Cryptographic Ciphers (Manual)"
output_1=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-authentication/configmaps/v4-0-config-system-cliconfig -o jsonpath='{.data.v4\-0\-config\-system\-cliconfig}' | jq '.servingInfo //empty')
output_2=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/apis/operator.openshift.io/v1/kubeapiservers/cluster |jq '.spec.observedConfig.servingInfo //empty')
output_3=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/apis/operator.openshift.io/v1/openshiftapiservers/cluster |jq '.spec.observedConfig.servingInfo //empty')
output_3=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/apis/operator.openshift.io/v1/namespaces/openshift-ingress-operator/ingresscontrollers/default )

if [ -z "$output_1" ] || [ -z "$output_2" ] || [ -z "$output_3" ] || [ -z "$output_4" ]; then
  warn "$check_1_2_35"
else
  pass "$check_1_2_35"
fi

info "1.3 - Controller Manager"

#todo review with Andson
check_1_3_1="1.3.1  - Ensure that garbage collection is configured as appropriate (Manual)"
info "$check_1_3_1"
info "Garbage collection is important to ensure sufficient resource availability and avoiding degraded performance and availability. In the worst case, the system might crash or just be unusable for a long period of time. The current setting for garbage collection is 12,500 terminated pods which might be too high for your system to sustain. Based on your system resources and tests, choose an appropriate threshold value to activate garbage collection."


## Filter out processes like "/bin/tee -a /var/log/kube-controller-manager.log"
## which exist on kops-managed clusters.
#if check_argument "$CIS_MANAGER_CMD" '--terminated-pod-gc-threshold' >/dev/null 2>&1; then
#    threshold=$(get_argument_value "$CIS_MANAGER_CMD" '--terminated-pod-gc-threshold')
#    pass "$check_1_3_1"
#    pass "       * terminated-pod-gc-threshold: $threshold"
#else
#    warn "$check_1_3_1"
#fi

check_1_3_2="1.3.2  - Ensure that controller manager healthz endpoints are protected by RBAC (Manual)"

info "$check_1_3_2"
info "Profiling allows for the identification of specific performance bottlenecks. It generates a significant amount of program data that could potentially be exploited to uncover system and program details. If you are not experiencing any bottlenecks and do not need the profiler for troubleshooting purposes, it is recommended to turn it off to reduce the potential attack surface."
#if check_argument "$CIS_MANAGER_CMD" '--profiling=false' >/dev/null 2>&1; then
#    pass "$check_1_3_2"
#else
#    warn "$check_1_3_2"
#fi

check_1_3_3="1.3.3  - Ensure that the --use-service-account-credentials argument is set to true (Manual)"
output=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-controller-manager/configmaps/config | jq -r '.data["config.yaml"]' | jq -r '.extendedArguments["use-service-account-credentials"]' | grep true)
if [ -n "$output" ]; then
  pass "$check_1_3_3"
else
  warn "$check_1_3_3"
fi

check_1_3_4="1.3.4  - Ensure that the --service-account-private-key-file argument is set as appropriate (Manual)"
output=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-controller-manager/configmaps/config | jq -r '.data["config.yaml"]' | jq -r '.extendedArguments["service-account-private-key-file"] //empty')
if [ -z "$output" ]; then
  warn "$check_1_3_4"
else
  pass "$check_1_3_4"
fi

check_1_3_5="1.3.5  - Ensure that the --root-ca-file argument is set as appropriate (Manual)"
output=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-controller-manager/configmaps/config | jq -r '.data["config.yaml"]' | jq -r '.extendedArguments["root-ca-file"] //empty')
if [ -z "$output" ]; then
  warn "$check_1_3_5"
else
  pass "$check_1_3_5"
fi

check_1_3_6="1.3.6  - Ensure that the RotateKubeletServerCertificate argument is set to true (Manual)"
output=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-controller-manager/configmaps/config | jq -r '.data["config.yaml"]' | jq '.extendedArguments["feature-gates"]' | grep "RotateKubeletServerCertificate=true")
if [ -z "$output" ]; then
  warn "$check_1_3_6"
else
  pass "$check_1_3_6"
fi


check_1_3_7="1.3.7  - Ensure that the --bind-address argument is set to 127.0.0.1 (Manual)"
output_1=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-controller-manager/configmaps/config | jq -r '.data["config.yaml"]' | jq '.extendedArguments["secure-port"] //empty')
output_2=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-controller-manager/configmaps/config | jq -r '.data["config.yaml"]' | jq '.extendedArguments["port"] //empty')
if [ -z "$output_1" ] || [ -z "$output_2" ]; then
  warn "$check_1_3_7"
else
  pass "$check_1_3_7"
fi

info "1.4 - Scheduler"

#todo not implemented
check_1_4_1="1.4.1  - Ensure that the healthz endpoints for the scheduler are protected by RBAC (Manual)"
info "$check_1_4_1"
info "Disable profiling, if not needed."
#if check_argument "$CIS_SCHEDULER_CMD" '--profiling=false' >/dev/null 2>&1; then
#  	pass "$check_1_4_1"
#else
#  	warn "$check_1_4_1"
#fi

#todo review
check_1_4_2="1.4.2  - Verify that the scheduler API service is protected by authentication and authorization (Manual)"
output=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-scheduler/configmaps/config | jq -r '.data["config.yaml"]' | jq '.extendedArguments["secure-port"] //empty' )
if [ -z "$output" ]; then
  pass "$check_1_4_2"
else
  warn "$check_1_4_2"
fi
#if get_argument_value "$CIS_SCHEDULER_CMD" '--bind-address'| grep '127.0.0.1' >/dev/null 2>&1; then
#  	pass "$check_1_4_2"
#else
#  	warn "$check_1_4_2"
#fiinfo "2 - etcd"

check_2_1="2.1  - Ensure that the --cert-file and --key-file arguments are set as appropriate (Manual)"
file="/etc/kubernetes/manifests/etcd-pod.yaml"
output_cert=$(grep "\(--cert-file=\)" $file)
output_key=$(grep "\(--key-file=\)" $file)
if [ -z "$output_cert" ] || [ -z "$output_key" ]; then
  warn "$check_2_1"
else
  pass "$check_2_1"
fi

check_2_2="2.2  - Ensure that the --client-cert-auth argument is set to true (Manual)"
file="/etc/kubernetes/manifests/etcd-pod.yaml"
output=$(grep "\(--client-cert-auth=true\)" $file)
if [ -z "$output" ]; then
    warn "$check_2_2"
else
    pass "$check_2_2"
fi

#todo review with Andson (OCP doesn't use auto-tls)
check_2_3="2.3  - Ensure that the --auto-tls argument is not set to true (Manual)"
file="/etc/kubernetes/manifests/etcd-pod.yaml"
output=$(grep "\(--auto-tls=true\)" $file)
if [ -z "$output" ]; then
    pass "$check_2_3"
else
    warn "$check_2_3"
fi

check_2_4="2.4  - Ensure that the --peer-cert-file and --peer-key-file arguments are set as appropriate (Manual)"
file="/etc/kubernetes/manifests/etcd-pod.yaml"
output_cert=$(grep "\(--peer-cert-file=\)" $file)
output_key=$(grep "\(--peer-key-file=\)" $file)
if [ -z "$output_cert" ] || [ -z "$output_key" ]; then
  warn "$check_2_4"
else
  pass "$check_2_4"
fi

check_2_5="2.5  - Ensure that the --peer-client-cert-auth argument is set to true (Manual)"
file="/etc/kubernetes/manifests/etcd-pod.yaml"
output=$(grep "\(--peer-client-cert-auth=true\)" $file)
if [ -z "$output" ]; then
    warn "$check_2_5"
else
    pass "$check_2_5"
fi

check_2_6="2.6  - Ensure that the --peer-auto-tls argument is not set to true (Manual)"
file="/etc/kubernetes/manifests/etcd-pod.yaml"
output=$(grep "\(--peer-auto-tls=true\)" $file)
if [ -z "$output" ]; then
    pass "$check_2_6"
else
    warn "$check_2_6"
fi

check_2_7="2.7  - Ensure that a unique Certificate Authority is used for etcd (Manual)"
file="/etc/kubernetes/manifests/etcd-pod.yaml"
output_1=$(grep "\(--trusted-ca-file=\)" $file)
output_2=$(grep "\(--peer-trusted-ca-file=\)" $file)
if [ -z "$output_1" ] || [ -z "$output_2" ]; then
    warn "$check_2_7"
else
    pass "$check_2_7"
fi
info "3 - Control Plane Configuration"

info "3.1 - Authentication and Authorization"

#todo review
check_3_1_1="3.1.1  - Client certificate authentication should not be used for users (Manual)"
output=$(find /etc/kubernetes/static-pod-resources -type f -wholename '*configmaps/client-ca/ca-bundle.crt')
if [ -z "$output" ]; then
  warn "$check_3_1_1"
else
  pass "check_3_1_1"
fi

info "3.2 - Logging"

#todo review with Andson (check recommended audit scripts)
check_3_2_1="3.2.1 - Ensure that a minimal audit policy is created (Manual)"
output=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-apiserver/configmaps/config | jq -r '.data["config.yaml"]' | jq '.auditConfig.auditFilePath','.auditConfig.enabled','.auditConfig.logFormat','.auditConfig.maximumFileSizeMegabytes','.auditConfig.maximumRetainedFiles')
if [ -z "$output" ]; then
  warn "$check_3_2_1"
else
  pass "$check_3_2_1"
fi

#todo review with Andson (Compliance TBD)
check_3_2_2="3.2.2 - Ensure that the audit policy covers key security concerns (Manual)"
output=$(curl -ks -H "Authorization: Bearer $OC_TOKEN" https://kubernetes.default/api/v1/namespaces/openshift-kube-apiserver/configmaps/config | jq -r '.data["config.yaml"]' | jq '.auditConfig.auditFilePath','.auditConfig.enabled','.auditConfig.logFormat','.auditConfig.maximumFileSizeMegabytes','.auditConfig.maximumRetainedFiles','.auditConfig.policyConfiguration')
if [ -z "$output" ]; then
  warn "$check_3_2_2"
else
  pass "$check_3_2_2"
fi
info "5 - Policies"
info "5.1 - RBAC and Service Accounts"

# Make the loop separator be a new-line in POSIX compliant fashion
set -f; IFS=$'
'

check_5_1_1="5.1.1  - Ensure that the cluster-admin role is only used where required (Manual)"
cluster_admins=$(kubectl get clusterrolebindings -o=custom-columns=NAME:.metadata.name,ROLE:.roleRef.name,SUBJECT:.subjects[*].name)
info "$check_5_1_1"
for admin in $cluster_admins; do
 	info "     * $admin"
done

check_5_1_2="5.1.2  - Minimize access to secrets (Manual)"
policies=$(kubectl get psp)
info "$check_5_1_2"
for policy in $policies; do
	  info "     * $policy"
done

check_5_1_3="5.1.3  - Minimize wildcard use in Roles and ClusterRoles (Manual)"
info "$check_5_1_3"

check_5_1_4="5.1.4  - Minimize access to create pods (Manual)"
policies=$(kubectl get pods --namespace=kube-system)
info "$check_5_1_4"
for policy in $policies; do
	info "     * $policy"
done

check_5_1_5="5.1.5  - Ensure that default service accounts are not actively used. (Manual)"
info "check_5_1_5"
info "The default service account should not be used to ensure that rights granted to applications can be more easily audited and reviewed."

#TODO
check_5_1_6="5.1.6  - Ensure that Service Account Tokens are only mounted where necessary (Manual)"
info "$check_5_1_6"
info "Service accounts tokens should not be mounted in pods except where the workload running in the pod explicitly needs to communicate with the API server"

info "5.2 - Pod Security Policies"

check_5_2_1="5.2.1  - Minimize the admission of privileged containers (Manual)"
info "$check_5_2_1"
info "Do not generally permit containers to be run with the securityContext.privileged flag set to true."
check_5_2_2="5.2.2  - Minimize the admission of containers wishing to share the host process ID namespace (Manual)"
info "$check_5_2_2"
info "Do not generally permit containers to be run with the hostPID flag set to true."
check_5_2_3="5.2.3  - Minimize the admission of containers wishing to share the host IPC namespace (Manual)"
info "$check_5_2_3"
info "Do not generally permit containers to be run with the hostIPC flag set to true."
check_5_2_4="5.2.4  - Minimize the admission of containers wishing to share the host network namespace (Manual)"
info "$check_5_2_4"
info "Do not generally permit containers to be run with the hostNetwork flag set to true."
check_5_2_5="5.2.5  - Minimize the admission of containers with allowPrivilegeEscalation (Manual)"
info "$check_5_2_5"
info "Do not generally permit containers to be run with the allowPrivilegeEscalation flag set to true."
check_5_2_6="5.2.6  - Minimize the admission of root containers (Manual)"
info "$check_5_2_6"
info "Do not generally permit containers to be run as the root user."
check_5_2_7="5.2.7  - Minimize the admission of containers with the NET_RAW capability (Manual)"
info "$check_5_2_7"
info "Do not generally permit containers with the potentially dangerous NET_RAW capability."
check_5_2_8="5.2.8  - Minimize the admission of containers with added capabilities (Manual)"
info "$check_5_2_8"
info "Do not generally permit containers with capabilities assigned beyond the default set."
check_5_2_9="5.2.9  - Minimize the admission of containers with capabilities assigned (Manual)"
info "$check_5_2_9"
info "Do not generally permit containers with capabilities"

info "5.3 - Network Policies and CNI"
check_5_3_1="5.3.1  - Ensure that the CNI in use supports Network Policies (Manual)"
info "$check_5_3_1"
info "There are a variety of CNI plugins available for Kubernetes. If the CNI in use does not support Network Policies it may not be possible to effectively restrict traffic in the cluster."
check_5_3_2="5.3.2  - Ensure that all Namespaces have Network Policies defined (Manual)"
info "$check_5_3_2"
info "Use network policies to isolate traffic in your cluster network."

info "5.4 - Secrets Management"
check_5_4_1="5.4.1  - Prefer using secrets as files over secrets as environment variables (Manual)"
info "$check_5_4_1"
info "Kubernetes supports mounting secrets as data volumes or as environment variables. Minimize the use of environment variable secrets."
check_5_4_2="5.4.2  - Consider external secret storage (Manual)"
info "$check_5_4_2"
info "Consider the use of an external secrets storage and management system, instead of using Kubernetes Secrets directly, if you have more complex secret management needs. Ensure the solution requires authentication to access secrets, has auditing of access to and use of secrets, and encrypts secrets. Some solutions also make it easier to rotate secrets."

info "5.5 - Extensible Admission Control"
check_5_5_1="5.5.1  - Configure Image Provenance using image controller configuration parameters (Manual)"
info "$check_5_5_1"
info "Configure Image Provenance for your deployment."

info "5.6 - General Policies"
check_5_6_1="5.6.1  - Create administrative boundaries between resources using namespaces (Manual)"
info "$check_5_6_1"
info "Use namespaces to isolate your Kubernetes objects."
#todo remedition
check_5_6_2="5.6.2  - Ensure that the seccomp profile is set to docker/default in your pod definitions (Manual)"
info "$check_5_6_2"
info "Enable default seccomp profile in your pod definitions."
check_5_6_3="5.6.3  - Apply Security Context to Your Pods and Containers (Manual)"
info "$check_5_6_3"
info "A security context defines the operating system security settings (uid, gid, capabilities, SELinux role, etc..) applied to a container. When designing your containers and pods, make sure that you configure the security context for your pods, containers, and volumes. A security context is a property defined in the deployment yaml. It controls the security parameters that will be assigned to the pod/container/volume. There are two levels of security context: pod level security context, and container level security context."
check_5_6_4="5.6.4  - The default namespace should not be used (Manual)"
info "$check_5_6_4"
info "Resources in a Kubernetes cluster should be segregated by namespace, to allow for security controls to be applied at that level and to make it easier to manage resources."
exit 0;