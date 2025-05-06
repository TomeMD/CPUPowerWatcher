#!/usr/bin/env bash

function get_date {
    DATE=`date '+%d/%m/%Y %H:%M:%S'`
}

export -f get_date

function m_echo() {
    get_date
    echo -e "\e[48;5;2m[$DATE INFO]\e[0m $@"
    echo "$DATE > $@" >> "${LOG_FILE}"
}

export -f m_echo

function m_err() {
    get_date
    echo -e "\e[48;5;1m[$DATE ERR]\e[0m $@" >&2
    echo "$DATE > $@" >> "${LOG_FILE}"
}

export -f m_err

function m_warn() {
    get_date
    echo -e "\e[48;5;208m[$DATE WARN]\e[0m $@"
    echo "$DATE > $@" >> "${LOG_FILE}"
}

export -f m_warn

function show_logo() {
	echo "                                                                   "
	echo " ____                      __        __    _       _               "
	echo "|  _ \ _____      _____ _ _\ \      / /_ _| |_ ___| |__   ___ _ __ "
	echo "| |_) / _ \ \ /\ / / _ \  __\ \ /\ / / _  | __/ __| |_ \ / _ \  __|"
	echo "|  __/ (_) \ V  V /  __/ |   \ V  V / (_| | || (__| | | |  __/ |   "
	echo "|_|   \___/ \_/\_/ \___|_|    \_/\_/ \__,_|\__\___|_| |_|\___|_|   "
	echo ""
}

export -f show_logo

function print_conf() {
    m_echo "InfluxDB host = ${INFLUXDB_HOST}"
    m_echo "InfluxDB bucket = ${INFLUXDB_BUCKET}"
    m_echo "OS Virtualization Technology = ${OS_VIRT}"
    m_echo "Workload = ${WORKLOAD}"
    if [ "${WORKLOAD}" == "stress-system" ]; then
      m_echo "\tStressors = [${STRESSORS}]"
      m_echo "\tCPU stress pattern = ${STRESS_PATTERN}"
      m_echo "\tCPU stress time = ${STRESS_TIME}s"
      m_echo "\tCPU idle time = ${IDLE_TIME}s"
      m_echo "\tCPU load types = [${LOAD_TYPES}]"
    fi
    if [ "${ADD_IO_NOISE}" -ne 0 ]; then
      m_echo "Fio target = ${FIO_TARGET}"
    fi
    if [ "${GET_BASE_MEASUREMENTS}" -ne 0 ]; then
      m_echo "Get base measurements = active"
    fi
    m_echo "Hardware info:"
    m_echo "\tPhysical cores per socket: ${PHY_CORES_PER_CPU}"
    m_echo "\tNumber of sockets: ${SOCKETS}"
    m_echo "\tNumber of threads: ${THREADS}"
    m_echo "\tMaximum supported load: ${MAX_SUPPORTED_LOAD}"
    m_echo "\tMultithreading support: ${MULTITHREADING_SUPPORT}"
    m_echo "\tCores with multithreading: (${CORES_WITH_MULTITHREADING[*]})"
    m_echo "Writing output to ${LOG_FILE}"
}

export -f print_conf

function print_time() {
	m_echo "${NAME} CPU TIME: $(bc <<< "scale=9; $(($2 - $1)) / 1000000000")" | tee -a "${LOG_FILE}"
}

export -f print_time

function print_timestamp() {
	local DESCRIPTION=$1
	m_echo "${NAME} ${DESCRIPTION}: $(date -u "+%Y-%m-%d %H:%M:%S%z")"
	echo "${NAME} ${DESCRIPTION}: $(date -u "+%Y-%m-%d %H:%M:%S%z")" >> "${TIMESTAMPS_FILE}"
}

export -f print_timestamp

function set_n_cores() {
  NUM_THREADS=$1
  CURRENT_CORES=""
  for (( i=0; i<NUM_THREADS; i++ )); do
    if [ "$i" -ne 0 ]; then
      CURRENT_CORES+=","
    fi
    CURRENT_CORES+="${CORES_ARRAY[i]}"
  done
}

export -f set_n_cores

function get_comma_separated_list() {
  local START="${1}"
  local END="${2}"
  local MSG=""
  for ((i = START; i < END; i += 1)); do
    MSG+="${i},"
  done
  MSG=${MSG:0:-1} # Remove last comma
  echo "${MSG}"
}

export -f get_comma_separated_list

function start_cpu_monitor() {
	CPU_MONITOR_STARTED=0
	MAX_TRIES=3
	while [ "${CPU_MONITOR_STARTED}" -eq 0 ] && [ "${MAX_TRIES}" -ne "0" ]
	do
      "${CPU_MONITOR_HOME}"/get-cpu-metrics.sh "${CURRENT_CORES}" "${INFLUXDB_HOST}" "${INFLUXDB_BUCKET}" > /dev/null 2>&1 &
      CPU_MONITOR_PID=$!
      sleep 1
      if ps -p "${CPU_MONITOR_PID}" > /dev/null; then
        CPU_MONITOR_STARTED=1
        m_echo "CPU monitoring agent succesfully started. (PID = ${CPU_MONITOR_PID})"
      else
        MAX_TRIES=$(( MAX_TRIES - 1 ))
        m_warn "Error while starting CPU monitoring agent. Trying again."
      fi
	done

	if [ "${MAX_TRIES}" -eq "0" ]; then
	  m_err "Exceeded maximum number of tries to start CPU monitor (cores = ${CURRENT_CORES})"
	  exit 1
	fi

    # Move CPU monitor to first core to account its usage on the models from the start, as core 0 is always included
    if [ -n "${CPU_MONITOR_PID}" ]; then
      taskset -cp "0" "${CPU_MONITOR_PID}"
      m_echo "Changed CPU monitor (pid = ${CPU_MONITOR_PID}) affinity to core 0"
    fi
}

export -f start_cpu_monitor

function stop_cpu_monitor() {
    CPU_MONITOR_KILLED=0
    MAX_TRIES=3
    while [ "${CPU_MONITOR_KILLED}" -eq 0 ] && [ "${MAX_TRIES}" -ne "0" ]
    do
      kill "${CPU_MONITOR_PID}" > /dev/null 2>&1
      if ps -p "${CPU_MONITOR_PID}" > /dev/null; then
        MAX_TRIES=$(( MAX_TRIES - 1 ))
        m_err "Error while killing CPU monitoring agent. (PID = ${CPU_MONITOR_PID})"
      else
        CPU_MONITOR_KILLED=1
        m_echo "CPU monitoring agent succesfully killed. (PID = ${CPU_MONITOR_PID})"
      fi
    done
    if [ "${MAX_TRIES}" -eq "0" ]; then
      m_err "Exceeded maximum number of tries to kill CPU monitor."
      exit 1
    fi
}

export -f stop_cpu_monitor

function get_str_list_from_array() {
  local ARRAY=("${@}")
  local MSG=""
  for ((i = 0; i < ${#ARRAY[@]}; i += 1)); do
    # Add new cores to the list
    if [ -z "${MSG}" ]; then
      MSG+="${ARRAY[i]}"
    else
      MSG+=",${ARRAY[i]}"
    fi
  done
  echo "${MSG}"
}

export -f get_str_list_from_array

function idle_cpu() {
	print_timestamp "IDLE START"
	sleep 30
	print_timestamp "IDLE STOP"
	sleep 5
}

export -f idle_cpu