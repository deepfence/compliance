source $DF_INSTALL_DIR/usr/local/bin/compliance_check/scripts/common.sh
source $DF_INSTALL_DIR/usr/local/bin/compliance_check/scripts/docker-bench-security/functions/helper_lib.sh
source $DF_INSTALL_DIR/usr/local/bin/compliance_check/scripts/kube-bench/helper1_6_0.sh
if [ -z "${NODE_TYPE}" ]
then
      NODE_TYPE="master"
fi
if [ -z "$CIS_VERSION" ]
then
      CIS_VERSION="1.6.0"
fi
source "/usr/local/bin/compliance_check/scripts/kube-bench/${CIS_VERSION}/${NODE_TYPE}.sh"

if [[ $NODE_TYPE == "master" ]]
then
  df_k8_1_1_1
  df_k8_1_1_2
  df_k8_1_1_3
else
  df_k8_4_1_1
  df_k8_4_1_2
  df_k8_4_1_3
  df_k8_4_1_4
  df_k8_4_1_5
  df_k8_4_1_6
  df_k8_4_1_7
  df_k8_4_1_8
  #df_k8_4_1_9
  #df_k8_4_1_10
fi
