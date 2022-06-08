
bldred='\033[1;31m' # Bold Red
bldgrn='\033[1;32m' # Bold Green
bldblu='\033[1;34m' # Bold Blue
bldylw='\033[1;33m' # Bold Yellow
txtrst='\033[0m'
logger="output.log"

if [ -n "$nocolor" ] && [ "$nocolor" = "nocolor" ]; then
  bldred=''
  bldgrn=''
  bldblu=''
  bldylw=''
  txtrst=''
fi

logit () {
  printf "%b\n" "$1" | tee -a "$logger"
}

info () {
  local infoCountCheck
  local OPTIND c
  while getopts c args
  do
    case $args in
    c) infoCountCheck="true" ;;
    *) exit 1 ;;
    esac
  done
  if [ "$infoCountCheck" = "true" ]; then
    printf "%b\n" "${bldblu}[INFO]${txtrst} $2" | tee -a "$logger"
    totalChecks=$((totalChecks + 1))
    return
  fi
  printf "%b\n" "${bldblu}[INFO]${txtrst} $1" | tee -a "$logger"
}

pass () {
  local passScored
  local passCountCheck
  local OPTIND s c
  while getopts sc args
  do
    case $args in
    s) passScored="true" ;;
    c) passCountCheck="true" ;;
    *) exit 1 ;;
    esac
  done
  if [ "$passScored" = "true" ] || [ "$passCountCheck" = "true" ]; then
    printf "%b\n" "${bldgrn}[PASS]${txtrst} $2" | tee -a "$logger"
    totalChecks=$((totalChecks + 1))
  fi
  if [ "$passScored" = "true" ]; then
    currentScore=$((currentScore + 1))
  fi
  if [ "$passScored" != "true" ] && [ "$passCountCheck" != "true" ]; then
    printf "%b\n" "${bldgrn}[PASS]${txtrst} $1" | tee -a "$logger"
  fi
}

warn () {
  local warnScored
  local OPTIND s
  while getopts s args
  do
    case $args in
    s) warnScored="true" ;;
    *) exit 1 ;;
    esac
  done
  if [ "$warnScored" = "true" ]; then
    printf "%b\n" "${bldred}[WARN]${txtrst} $2" | tee -a "$logger"
    totalChecks=$((totalChecks + 1))
    currentScore=$((currentScore - 1))
    return
  fi
  printf "%b\n" "${bldred}[WARN]${txtrst} $1" | tee -a "$logger"
}

note () {
  local noteCountCheck
  local OPTIND c
  while getopts c args
  do
    case $args in
    c) noteCountCheck="true" ;;
    *) exit 1 ;;
    esac
  done
  if [ "$noteCountCheck" = "true" ]; then
    printf "%b\n" "${bldylw}[NOTE]${txtrst} $2" | tee -a "$logger"
    totalChecks=$((totalChecks + 1))
    return
  fi
  printf "%b\n" "${bldylw}[NOTE]${txtrst} $1" | tee -a "$logger"
}

logbenchjson () {
  printf "{\"Level\":\"%s\",\"TestNum\":\"%s\",\"TestCategory\":\"%s\",\"Header\":\"%s\",\"Message\":\"%s\",\"Remediation\":\"%s\",\"RemediationImpact\":\"%s\"}\n" "$1" "$2" "$3" "$4" "$5" "$6" "$7" | tee -a "$logger"
}

yell () {
  printf "%b\n" "${bldylw}$1${txtrst}\n"
}

beginjson () {
  printf "{\n  \"dockerbenchsecurity\": \"%s\",\n  \"start\": %s,\n  \"tests\": [" "$1" "$2" | tee "$logger.json" 2>/dev/null 1>&2
}

endjson (){
  printf "\n  ],\n  \"checks\": %s,\n  \"score\": %s,\n  \"end\": %s\n}" "$1" "$2" "$3" | tee -a "$logger.json" 2>/dev/null 1>&2
}

logjson (){
  printf "\n  \"%s\": \"%s\"," "$1" "$2" | tee -a "$logger.json" 2>/dev/null 1>&2
}

SSEP=
SEP=
startsectionjson() {
  printf "%s\n    {\n      \"id\": \"%s\",\n      \"desc\": \"%s\",\n      \"results\": [" "$SSEP" "$1" "$2" | tee -a "$logger.json" 2>/dev/null 1>&2
  SEP=
  SSEP=","
}

endsectionjson() {
  printf "\n      ]\n    }" | tee -a "$logger.json" 2>/dev/null 1>&2
}

starttestjson() {
  printf "%s\n        {\n          \"id\": \"%s\",\n          \"desc\": \"%s\",\n          " "$SEP" "$1" "$2" | tee -a "$logger.json" 2>/dev/null 1>&2
  SEP=","
}

log_to_json() {
  if [ $# -eq 1 ]; then
    printf "\"result\": \"%s\"" "$1" | tee -a "$logger.json" 2>/dev/null 1>&2
    return
  fi
  if [ $# -eq 2 ] && [ $# -ne 1 ]; then
    # Result also contains details
    printf "\"result\": \"%s\",\n          \"details\": \"%s\"" "$1" "$2" | tee -a "$logger.json" 2>/dev/null 1>&2
    return
  fi
  # Result also includes details and a list of items. Add that directly to details and to an array property "items"
  # Also limit the number of items to $limit, if $limit is non-zero
  truncItems=$3
  if [ "$limit" != 0 ]; then
    truncItems=""
    ITEM_COUNT=0
    for item in $3; do
      truncItems="$truncItems $item"
      ITEM_COUNT=$((ITEM_COUNT + 1));
      if [ "$ITEM_COUNT" == "$limit" ]; then
        truncItems="$truncItems (truncated)"
        break;
      fi
    done
  fi
  itemsJson=$(printf "[\n            "; ISEP=""; ITEMCOUNT=0; for item in $truncItems; do printf "%s\"%s\"" "$ISEP" "$item"; ISEP=","; done; printf "\n          ]")
  printf "\"result\": \"%s\",\n          \"details\": \"%s: %s\",\n          \"items\": %s" "$1" "$2" "$truncItems" "$itemsJson" | tee -a "$logger.json" 2>/dev/null 1>&2
}

logcheckresult() {
  # Log to JSON
  log_to_json "$@"

  # Log remediation measure to JSON
  if [ -n "$remediation" ] && [ "$1" != "PASS" ] && [ "$printremediation" = "1" ]; then
    printf ",\n          \"remediation\": \"%s\"" "$remediation" | tee -a "$logger.json" 2>/dev/null 1>&2
    if [ -n "$remediationImpact" ]; then
      printf ",\n          \"remediation-impact\": \"%s\"" "$remediationImpact" | tee -a "$logger.json" 2>/dev/null 1>&2
    fi
  fi
  printf "\n        }" | tee -a "$logger.json" 2>/dev/null 1>&2

  # Save remediation measure for print log to stdout
  if [ -n "$remediation" ] && [ "$1" != "PASS" ]; then
    if [ -n "${checkHeader}" ]; then
      if [ -n "${addSpaceHeader}" ]; then
        globalRemediation="${globalRemediation}\n"
      fi
      globalRemediation="${globalRemediation}\n${bldblu}[INFO]${txtrst} ${checkHeader}"
      checkHeader=""
      addSpaceHeader="1"
    fi
    globalRemediation="${globalRemediation}\n${bldblu}[INFO]${txtrst} ${id} - ${remediation}"
    if [ -n "${remediationImpact}" ]; then
      globalRemediation="${globalRemediation} Remediation Impact: ${remediationImpact}"
    fi
  fi
}


# Compares versions of software of the format X.Y.Z
do_version_check() {
  [ "$1" = "$2" ] && return 10

  ver1front=$(printf "%s" "$1" | cut -d "." -f -1)
  ver1back=$(printf "%s" "$1" | cut -d "." -f 2-)
  ver2front=$(printf "%s" "$2" | cut -d "." -f -1)
  ver2back=$(printf "%s" "$2" | cut -d "." -f 2-)

  if [ "$ver1front" != "$1" ] || [ "$ver2front" != "$2" ]; then
    [ "$ver1front" -gt "$ver2front" ] && return 11
    [ "$ver1front" -lt "$ver2front" ] && return 9

    [ "$ver1front" = "$1" ] || [ -z "$ver1back" ] && ver1back=0
    [ "$ver2front" = "$2" ] || [ -z "$ver2back" ] && ver2back=0
      do_version_check "$ver1back" "$ver2back"
      return $?
  fi
  [ "$1" -gt "$2" ] && return 11 || return 9
}

# Extracts commandline args from the newest running processes named like the first parameter
get_command_line_args() {
  PROC="$1"

  for PID in $(pgrep -f -n "$PROC"); do
    tr "\0" " " < /proc/"$PID"/cmdline
  done
}

# Extract the cumulative command line arguments for the docker daemon
#
# If specified multiple times, all matches are returned.
# Accounts for long and short variants, call with short option.
# Does not account for option defaults or implicit options.
get_docker_cumulative_command_line_args() {
  OPTION="$1"

  line_arg="dockerd"
  if ! get_command_line_args "docker daemon" >/dev/null 2>&1 ; then
    line_arg="docker daemon"
  fi

  echo "<<<.Replace_docker_daemon_opts>>>" |
  # normalize known long options to their short versions
  sed \
    -e 's/\-\-debug/-D/g' \
    -e 's/\-\-host/-H/g' \
    -e 's/\-\-log-level/-l/g' \
    -e 's/\-\-version/-v/g' \
    |
    # normalize parameters separated by space(s) to -O=VALUE
    sed \
      -e 's/\-\([DHlv]\)[= ]\([^- ][^ ]\)/-\1=\2/g' \
      |
    # get the last interesting option
    tr ' ' "\n" |
    grep "^${OPTION}" |
    # normalize quoting of values
    sed \
      -e 's/"//g' \
      -e "s/'//g"
}

# Extract the effective command line arguments for the docker daemon
#
# Accounts for multiple specifications, takes the last option.
# Accounts for long and short variants, call with short option
# Does not account for option default or implicit options.
get_docker_effective_command_line_args() {
  OPTION="$1"
  get_docker_cumulative_command_line_args "$OPTION" | tail -n1
}

get_docker_configuration_file() {
  FILE="$(get_docker_effective_command_line_args '--config-file' | \
    sed 's/.*=//g')"

  if [ -f "$FILE" ]; then
    CONFIG_FILE="$FILE"
    return
  fi
  if [ -f '/etc/docker/daemon.json' ]; then
    CONFIG_FILE='/etc/docker/daemon.json'
    return
  fi
  CONFIG_FILE='/dev/null'
}

get_docker_configuration_file_args() {
  OPTION="$1"

  get_docker_configuration_file

  grep "$OPTION" "$CONFIG_FILE" | sed 's/.*://g' | tr -d '" ',
}

get_service_file() {
  SERVICE="$1"

  if [ -f "/etc/systemd/system/$SERVICE" ]; then
    echo "/etc/systemd/system/$SERVICE"
    return
  fi
  if [ -f "/lib/systemd/system/$SERVICE" ]; then
    echo "/lib/systemd/system/$SERVICE"
    return
  fi
  if systemctl show -p FragmentPath "$SERVICE" 2> /dev/null 1>&2; then
    systemctl show -p FragmentPath "$SERVICE" | sed 's/.*=//'
    return
  fi
  echo "/usr/lib/systemd/system/$SERVICE"
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