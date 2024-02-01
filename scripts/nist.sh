source $DF_INSTALL_DIR/usr/local/bin/compliance_check/scripts/common.sh
source $DF_INSTALL_DIR/usr/local/bin/compliance_check/scripts/docker-bench-security/functions/helper_lib.sh
source $DF_INSTALL_DIR/usr/local/bin/compliance_check/scripts/docker-bench-security/tests/1_host_configuration.sh
source $DF_INSTALL_DIR/usr/local/bin/compliance_check/scripts/docker-bench-security/tests/2_docker_daemon_configuration.sh
source $DF_INSTALL_DIR/usr/local/bin/compliance_check/scripts/docker-bench-security/tests/3_docker_daemon_configuration_files.sh
source $DF_INSTALL_DIR/usr/local/bin/compliance_check/scripts/docker-bench-security/tests/4_container_images.sh
source $DF_INSTALL_DIR/usr/local/bin/compliance_check/scripts/docker-bench-security/tests/5_container_runtime.sh

check_1_2_2
check_1_1_18
check_1_1_5
check_1_1_6
check_1_1_7
check_1_1_9
check_1_1_10
check_1_1_13
check_1_1_14

check_2_5
check_2_7
check_2_14


check_3_2
check_3_3
check_3_4
check_3_5
check_3_6
check_3_7
check_3_8
check_3_9
check_3_10
check_3_11
check_3_12
check_3_13
check_3_14
check_3_15
check_3_16
check_3_17
check_3_18
check_3_19
check_3_20
check_3_21
check_3_22

check_4_8


#check_5_4
#check_5_5
#check_5_6
#check_5_7
#check_5_17
#check_5_25
#check_5_31
#check_5_12
#check_5_30