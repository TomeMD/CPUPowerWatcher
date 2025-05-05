#!/usr/bin/env bash

if [ $# -ne 3 ]; then
  echo "Error: Missing some arguments"
  echo "Usage: $0 <CORES_LIST> <INFLUXDB_HOST> <INFLUXDB_BUCKET>"
  exit 1
fi

CORES_LIST=$1
IFS=',' read -ra CORES_ARRAY <<< "${CORES_LIST}"
INFLUXDB_HOST=$2
INFLUXDB_BUCKET=$3

SCRIPT_DIR=$(dirname -- "$(readlink -f -- "${BASH_SOURCE}")")
source "${SCRIPT_DIR}/config.sh"

SYS_CPU_PATH="/sys/devices/system/cpu"
SYS_TEMP_PATH="/sys/class/thermal"
SYS_CLK_TCK=$(getconf CLK_TCK)

#####################################################################################################################
# Temperature initialization
#####################################################################################################################
if [ "${MONITOR_TEMPERATURE}" -gt "0" ]; then
  if [ ! -r "${SYS_TEMP_PATH}" ]; then
      echo "Error: No read access to temperature info from sysfs: ${SYS_TEMP_PATH}"
      exit 1
  fi
fi

#####################################################################################################################
# Voltage initialization
#####################################################################################################################
if [ "${MONITOR_VOLTAGE}" -gt "0" ]; then
  if ! command -v rdmsr &> /dev/null; then
      echo "Error: rdmsr command not found. Please install msr-tools."
      exit 1
  fi
  if ! rdmsr 0x198 2> /dev/null; then
      echo "Error: rdmsr command could not be executed. Ensure you have root privileges."
      exit 1
  fi
fi

#####################################################################################################################
# C-States initialization
#####################################################################################################################
if [ "${MONITOR_CSTATES}" -gt "0" ]; then
  readarray -t CSTATE_NAMES < <(cat "${SYS_CPU_PATH}"/cpu0/cpuidle/state*/name)
  NUM_CSTATES=${#CSTATE_NAMES[@]}
  CSTATE_TIMES_FILES=()
  # Array: (<cpu0-state0> ... <cpu0-stateM> <cpu1-state0> ... <cpu1-stateM> ... <cpuN-state0> ... <cpuN-stateM>)
  for CORE in "${CORES_ARRAY[@]}"; do
      for (( i=0; i<NUM_CSTATES; i++ )); do
        CSTATE_TIMES_FILES+=("${SYS_CPU_PATH}/cpu${CORE}/cpuidle/state${i}/time")
      done
  done
  PREV_CSTATE_TIMES=($(printf "0 %.0s" "${CSTATE_TIMES_FILES[@]}"))
  PREV_CSTATE_TOTAL_TIME_CORE=($(printf "0 %.0s" $(seq 1 ${#CORES_ARRAY[@]})))
  CSTATE_PCT_CORE_ZERO=($(printf "0 %.0s" $(seq 1 ${NUM_CSTATES})))
  CSTATE_PCT_CORE=("${CSTATE_PCT_CORE_ZERO[@]}")
fi

#####################################################################################################################
# CPU usage/frequency initialization
#####################################################################################################################
if [ ! -r "${SYS_CPU_PATH}" ]; then
    echo "Error: No read access to CPU info from sysfs: ${SYS_CPU_PATH}"
    exit 1
fi

declare -a PREV_USER
declare -a PREV_SYSTEM
declare -a PREV_IOWAIT
declare -a PREV_TOTAL

for CORE in "${CORES_ARRAY[@]}"; do
  PREV_USER[${CORE}]=0
  PREV_SYSTEM[${CORE}]=0
  PREV_IOWAIT[${CORE}]=0
  PREV_TOTAL[${CORE}]=0
done

#####################################################################################################################
# Physical/Logical cores map initialization
#####################################################################################################################
if [ "${SEPARATE_MULTITHREADING_USAGE}" -gt "0" ]; then
  # Array to register cores already found
  NUM_THREADS=$(lscpu | grep -e "^CPU(s):" | awk '{print $2}')
  CORE_FOUND=()
  for (( i=0; i<NUM_THREADS; i++ )); do
    CORE_FOUND[${i}]=0
  done

  # Build a map of physical and logical cores
  OUTPUT=$(lscpu -e | awk 'NR > 1 { print $1, $4 }')
  declare -A LOG_PHY_MAPPING
  while read -r CPU CORE; do
    if [ "${CORE_FOUND[${CORE}]}" -eq "0" ];then # If we found a second CPU in the same core we mark it as a logical core
      LOG_PHY_MAPPING[${CPU}]=1
      CORE_FOUND[${CORE}]=1
    else
      LOG_PHY_MAPPING[${CPU}]=0
    fi
  done <<< "${OUTPUT}"
fi

function compute_cpu_elapsed_time() {
    local TOTAL_TIME=0

    for TIME in "${CPU_CORE_TIMES[@]}"; do
      TOTAL_TIME=$(( TOTAL_TIME + TIME ))
    done
    CPU_ELAPSED_TIME=$((TOTAL_TIME - PREV_TOTAL[CORE]))
    #CPU_ELAPSED_TIME_MS=$(( 1000000 * CPU_ELAPSED_TIME / SYS_CLK_TCK))
    PREV_TOTAL[$CORE]=${TOTAL_TIME}
}

function compute_core_usages() {
  local DIFF_USER=$((CPU_CORE_TIMES[1] - PREV_USER[CORE]))
  local DIFF_SYSTEM=$((CPU_CORE_TIMES[3] - PREV_SYSTEM[CORE]))
  local DIFF_IOWAIT=$((CPU_CORE_TIMES[5] - PREV_IOWAIT[CORE]))


  USER_USAGE_CORE=$((100 * DIFF_USER / CPU_ELAPSED_TIME))
  SYSTEM_USAGE_CORE=$((100 * DIFF_SYSTEM / CPU_ELAPSED_TIME))
  IOWAIT_USAGE_CORE=$((100 * DIFF_IOWAIT / CPU_ELAPSED_TIME))

  PREV_USER[$CORE]=${CPU_CORE_TIMES[1]}
  PREV_SYSTEM[$CORE]=${CPU_CORE_TIMES[3]}
  PREV_IOWAIT[$CORE]=${CPU_CORE_TIMES[5]}

}

function compute_cstates_usage() {

  local CSTATE_TOTAL_TIME=0
  local DIFF_CSTATES_CORE=()

  # Get current time for all available C-states
  for (( i=0; i<NUM_CSTATES; i++ )); do
    POSITION=$(( CSTATE_CORE_OFFSET + i ))
    DIFF_CSTATES_CORE["${i}"]=$(( CSTATE_TIMES["${POSITION}"] - PREV_CSTATE_TIMES["${POSITION}"] ))
    PREV_CSTATE_TIMES["${POSITION}"]=${CSTATE_TIMES["${POSITION}"]}
    CSTATE_TOTAL_TIME=$(( CSTATE_TOTAL_TIME + CSTATE_TIMES["${POSITION}"] ))
  done

  # Get total elapsed time for C-States
  DIFF_TOTAL=$(( CSTATE_TOTAL_TIME - PREV_CSTATE_TOTAL_TIME_CORE["${CORE}"] ))
  PREV_CSTATE_TOTAL_TIME_CORE["${CORE}"]="${CSTATE_TOTAL_TIME}"

  # If elapsed time is zero, just send all state percentages as zero (avoid zero division)
  if [ "${DIFF_TOTAL}" -eq "0" ]; then
      CSTATE_PCT_CORE=("${CSTATE_PCT_CORE_ZERO[@]}")
  else
    # For each C-State get percentage over total C-States time
    for (( i=0; i<NUM_CSTATES; i++ )); do
      CSTATE_PCT_CORE[${i}]=$(( 100 * DIFF_CSTATES_CORE["${i}"] / DIFF_TOTAL ))
    done
  fi

  CSTATE_CORE_OFFSET=$(( CSTATE_CORE_OFFSET + NUM_CSTATES ))
}

function read_cpu_temperature() {
    local TEMP
    for FILE in "${SYS_TEMP_PATH}"/thermal_zone*/temp; do
        read -r TEMP < "${FILE}"
        DATA+=",temp${FILE:31:1}=$(( TEMP / 1000 ))"
    done
}

while true; do
    TOTAL_FREQ=0; USER_USAGE=0; SYSTEM_USAGE=0; IOWAIT_USAGE=0; CSTATE_CORE_OFFSET=0
    CPU_ELAPSED_TIME=0, CPU_ELAPSED_TIME_MS=0, CPU_CORE_TIMES=()
    P_L_USER=(0 0); P_L_SYSTEM=(0 0)

    # Read values
    START_TIMESTAMP=$(date +%s%N)
    readarray -t PROC_LINES < /proc/stat # 3ms
    if [ "${MONITOR_CSTATES}" -gt "0" ];then # 17ms
      readarray -t CSTATE_TIMES < <(cat "${CSTATE_TIMES_FILES[@]}")
    fi

    DATA=""
    #TIMESTAMP=$(date +%s%N)
    for CORE in "${CORES_ARRAY[@]}"; do

      # Frequency
      FREQ_CORE=$(<"${SYS_CPU_PATH}/cpu${CORE}/cpufreq/scaling_cur_freq")

      # CPU usage
      CPU_CORE_TIMES=(${PROC_LINES[$(( CORE + 1 ))]})
      compute_cpu_elapsed_time
      compute_core_usages
      TOTAL_FREQ=$((TOTAL_FREQ + FREQ_CORE))
      USER_USAGE=$((USER_USAGE + USER_USAGE_CORE))
      SYSTEM_USAGE=$((SYSTEM_USAGE + SYSTEM_USAGE_CORE))
      IOWAIT_USAGE=$((IOWAIT_USAGE + IOWAIT_USAGE_CORE))

      # Separate physical and logical usage
      if [ "${SEPARATE_MULTITHREADING_USAGE}" -gt "0" ]; then
        P_L_USER[${LOG_PHY_MAPPING[${CORE}]}]=$(( P_L_USER[${LOG_PHY_MAPPING[${CORE}]}] + USER_USAGE_CORE ))
        P_L_SYSTEM[${LOG_PHY_MAPPING[${CORE}]}]=$(( P_L_SYSTEM[${LOG_PHY_MAPPING[${CORE}]}] + SYSTEM_USAGE_CORE ))
      fi

      # Add core base data
      DATA+="cpu_metrics,core=${CORE} freq=${FREQ_CORE},user=${USER_USAGE_CORE},system=${SYSTEM_USAGE_CORE},iowait=${IOWAIT_USAGE_CORE}"

      # Add C-States
      if [ "${MONITOR_CSTATES}" -gt "0" ];then
        compute_cstates_usage
        for (( i=0; i<NUM_CSTATES; i++ )); do
          DATA+=",${CSTATE_NAMES[${i}]}=${CSTATE_PCT_CORE[${i}]}"
        done
      fi

      # Add voltage
      if [ "${MONITOR_VOLTAGE}" -gt "0" ];then
        VOLTAGE_CORE=$(rdmsr -p "${CORE}" 0x198 -u --bitfield 47:32 | awk '{printf "%.2f", $1/8192}')
        DATA+=",vcore=${VOLTAGE_CORE}"
      fi

      # Add timestamp
      DATA+=" ${START_TIMESTAMP}\n"

    done
    AVG_FREQ=$((TOTAL_FREQ / ${#CORES_ARRAY[@]} / 1000))

    # Add global data
    DATA+="cpu_metrics,core=all avgfreq=${AVG_FREQ},sumfreq=${TOTAL_FREQ},user=${USER_USAGE},system=${SYSTEM_USAGE},iowait=${IOWAIT_USAGE}"
    if [ "${MONITOR_TEMPERATURE}" -gt "0" ]; then
      read_cpu_temperature
    fi
    if [ "${SEPARATE_MULTITHREADING_USAGE}" -gt "0" ]; then
      DATA+=",puser=${P_L_USER[1]},luser=${P_L_USER[0]},psystem=${P_L_SYSTEM[1]},lsystem=${P_L_SYSTEM[0]}"
    fi
    DATA+=" ${START_TIMESTAMP}"

    # Send data to InfluxDB
    echo -e "${DATA}" | curl -s -XPOST "http://${INFLUXDB_HOST}:8086/api/v2/write?org=MyOrg&bucket=${INFLUXDB_BUCKET}" --header "Authorization: Token MyToken" --data-binary @-
    sleep "${SAMPLING_FREQUENCY}"
done