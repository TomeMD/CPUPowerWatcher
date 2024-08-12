#!/bin/bash

if [ $# -ne 3 ]; then
  echo "Error: Missing some arguments"
  echo "Usage: $0 <CORES_LIST> <INFLUXDB_HOST> <INFLUXDB_BUCKET>"
  exit 1
fi

CORES_LIST=$1
IFS=',' read -ra CORES_ARRAY <<< "${CORES_LIST}"
INFLUXDB_HOST=$2
INFLUXDB_BUCKET=$3
SAMPLING_FREQUENCY=1

# Build a map of physical and logical cores
declare -A LOG_PHY_MAPPING
NUM_THREADS=$(lscpu | grep -e "^CPU(s):" | awk '{print $2}')

# Array to register cores already found
CORE_FOUND=()
for (( i=0; i<NUM_THREADS; i++ )); do
  CORE_FOUND[${i}]=0
done

# If we found a second CPU in the same core we mark it as a logical core
OUTPUT=$(lscpu -e | awk 'NR > 1 { print $1, $4 }')
while read -r CPU CORE; do
  if [ "${CORE_FOUND[${CORE}]}" -eq "0" ];then
    LOG_PHY_MAPPING[${CPU}]=1
    CORE_FOUND[${CORE}]=1
  else
    LOG_PHY_MAPPING[${CPU}]=0
  fi
done <<< "$OUTPUT"

function compute_core_utilization() {
  local CPU_TIMES=(${PROC_LINES[$(( CORE + 1 ))]})
  local TOTAL_TIME=0
  for TIME in "${CPU_TIMES[@]}"; do
    TOTAL_TIME=$((TOTAL_TIME + TIME))
  done

  local DIFF_USER=$((CPU_TIMES[1] - PREV_USER[CORE]))
  local DIFF_SYSTEM=$((CPU_TIMES[3] - PREV_SYSTEM[CORE]))
  local DIFF_IOWAIT=$((CPU_TIMES[5] - PREV_IOWAIT[CORE]))
  local DIFF_TOTAL=$((TOTAL_TIME - PREV_TOTAL[CORE]))

  USER_UTIL_CORE=$((100 * DIFF_USER / DIFF_TOTAL))
  SYSTEM_UTIL_CORE=$((100 * DIFF_SYSTEM / DIFF_TOTAL))
  IOWAIT_UTIL_CORE=$((100 * DIFF_IOWAIT / DIFF_TOTAL))

  PREV_USER[$CORE]=${CPU_TIMES[1]}
  PREV_SYSTEM[$CORE]=${CPU_TIMES[3]}
  PREV_IOWAIT[$CORE]=${CPU_TIMES[5]}
  PREV_TOTAL[$CORE]=${TOTAL_TIME}
}

function read_cpu_temperature() {
    local TEMP
    TOTAL_TEMP=0
    for FILE in /sys/class/thermal/thermal_zone*/temp; do
        read -r TEMP < "${FILE}"
        TOTAL_TEMP=$((TOTAL_TEMP + TEMP))
    done
    TOTAL_TEMP=$((TOTAL_TEMP / 1000))
}

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

while true; do
    TOTAL_FREQ=0; TOTAL_TEMP=0; USER_UTIL=0; SYSTEM_UTIL=0; IOWAIT_UTIL=0
    P_L_USER=(0 0); P_L_SYSTEM=(0 0)
    readarray -t PROC_LINES < /proc/stat

    DATA=""
    TIMESTAMP=$(date +%s%N)
    for CORE in "${CORES_ARRAY[@]}"; do
      FREQ_CORE=$(<"/sys/devices/system/cpu/cpu${CORE}/cpufreq/scaling_cur_freq")
      compute_core_utilization
      TOTAL_FREQ=$((TOTAL_FREQ + FREQ_CORE))
      USER_UTIL=$((USER_UTIL + USER_UTIL_CORE))
      SYSTEM_UTIL=$((SYSTEM_UTIL + SYSTEM_UTIL_CORE))
      IOWAIT_UTIL=$((IOWAIT_UTIL + IOWAIT_UTIL_CORE))

      # Separate physical and logical usage
      P_L_USER[${LOG_PHY_MAPPING[${CORE}]}]=$(( P_L_USER[${LOG_PHY_MAPPING[${CORE}]}] + USER_UTIL_CORE ))
      P_L_SYSTEM[${LOG_PHY_MAPPING[${CORE}]}]=$(( P_L_SYSTEM[${LOG_PHY_MAPPING[${CORE}]}] + SYSTEM_UTIL_CORE ))

      # Add core data
      DATA+="cpu_metrics,core=${CORE} freq=${FREQ_CORE},user=${USER_UTIL_CORE},system=${SYSTEM_UTIL_CORE},iowait=${IOWAIT_UTIL_CORE} ${TIMESTAMP}\n"
    done
    AVG_FREQ=$((TOTAL_FREQ / ${#CORES_ARRAY[@]} / 1000))
    read_cpu_temperature

    # Add global data
    DATA+="cpu_metrics,core=all avgfreq=${AVG_FREQ},sumfreq=${TOTAL_FREQ},user=${USER_UTIL},puser=${P_L_USER[1]},luser=${P_L_USER[0]},system=${SYSTEM_UTIL},psystem=${P_L_SYSTEM[1]},lsystem=${P_L_SYSTEM[0]},iowait=${IOWAIT_UTIL},temp=${TOTAL_TEMP} ${TIMESTAMP}"

    # Send data to InfluxDB
    echo -e "${DATA}" | curl -s -XPOST "http://${INFLUXDB_HOST}:8086/api/v2/write?org=MyOrg&bucket=${INFLUXDB_BUCKET}" --header "Authorization: Token MyToken" --data-binary @-
    sleep "${SAMPLING_FREQUENCY}"
done