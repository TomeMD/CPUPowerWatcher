#!/bin/sh

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
    show_logo
    m_echo "InfluxDB host = ${INFLUXDB_HOST}"
    m_echo "InfluxDB bucket = ${INFLUXDB_BUCKET}"
    m_echo "OS Virtualization Technology = ${OS_VIRT}"
    m_echo "Workload = ${WORKLOAD}"
    if [ "${WORKLOAD}" == "stress-system" ]; then
      m_echo "Stress-system stressors = [${STRESSORS}]"
      m_echo "CPU Stressor Load Types = [${LOAD_TYPES}]"
    fi
    if [ "${ADD_IO_NOISE}" -ne 0 ]; then
      m_echo "Fio target = ${FIO_TARGET}"
    fi
    if [ "${GET_BASE_MEASUREMENTS}" -ne 0 ]; then
      m_echo "Get base measurements = active"
    fi
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

function get_bind_from_stress_options() {
  local BIND_MOUNT=""
  if [ -n "${STRESS_EXTRA_OPTS}" ]; then
    for OPT in "${STRESS_EXTRA_OPTS_ARRAY[@]}"; do
      IFS='=' read KEY VALUE <<< "${OPT}"
      if [ "${KEY}" == "temp-path" ]; then
        if [ "${OS_VIRT}" == "docker" ]; then
          BIND_MOUNT="-v ${VALUE}:${VALUE} "
        else
          BIND_MOUNT="-B ${VALUE}:${VALUE} "
        fi
      fi
    done
  fi
  echo "${BIND_MOUNT}"
}

export -f get_bind_from_stress_options

function run_stress-system() {
    local CPU_QUOTA=$(echo "scale=2; ${LOAD} / 100 " | bc)
    local STRESS_TIME=120
    # Check if we have to set a bind mount for container (e.g., iomix stressor needs to write in host directory)
    local BIND_MOUNT=$(get_bind_from_stress_options)
    # Stress-system does weird things when we specify LOAD < 100 (in this case load is adjusted with CPU quota)
    local OLD_LOAD="${LOAD}"
    if [ "${LOAD}" -lt "100" ];then
      LOAD=100
    fi

    # Set container and Stress-system options
    local CONTAINER_OPTS="${BIND_MOUNT}--cpuset-cpus ${CURRENT_CORES} --cpus ${CPU_QUOTA}"
    local STRESS_OPTS="${STRESS_EXTRA_OPTS}-l ${LOAD} -s ${STRESSORS} --cpu-load-types ${LOAD_TYPES} -c ${CURRENT_CORES} -t ${STRESS_TIME} -o /opt"

	print_timestamp "STRESS-TEST (CORES = ${CURRENT_CORES}) START"
	if [ "${OS_VIRT}" == "docker" ]; then
	    m_echo "docker run --rm --name stress-system -v ${STRESS_REPORTS_DIR}:/opt ${CONTAINER_OPTS} -it stress-system ${STRESS_OPTS}"
		docker run --rm --name stress-system -v "${STRESS_REPORTS_DIR}:/opt" ${CONTAINER_OPTS} -it stress-system ${STRESS_OPTS} >> "${LOG_FILE}" 2>&1
	else
	    m_echo "sudo apptainer instance start -B ${STRESS_REPORTS_DIR}:/opt ${CONTAINER_OPTS} ${STRESS_CONTAINER_DIR}/stress.sif stress_system ${STRESS_OPTS}"
		sudo apptainer instance start -B "${STRESS_REPORTS_DIR}:/opt" ${CONTAINER_OPTS} "${STRESS_CONTAINER_DIR}/stress.sif" stress_system ${STRESS_OPTS} >> "${LOG_FILE}" 2>&1
	fi

	sleep "${STRESS_TIME}"
	# Apptainer requires using instances to apply CPU constraints, thus an instance must be deployed and destroyed
	if [ "${OS_VIRT}" == "apptainer" ]; then
		sudo apptainer instance stop stress_system
	fi
	print_timestamp "STRESS-TEST (CORES = ${CURRENT_CORES}) STOP"

	# Reset LOAD to its original value
	LOAD="${OLD_LOAD}"

	sleep 20
}

export -f run_stress-system

function run_sysbench() {
	print_timestamp "SYSBENCH (CORES = ${CURRENT_CORES}) START"
	if [ "${OS_VIRT}" == "docker" ]; then
		docker run --rm --name sysbench -it sysbench "${CURRENT_CORES}" >> "${LOG_FILE}" 2>&1
	else
		apptainer run "${SYSBENCH_HOME}"/sysbench.sif "${CURRENT_CORES}" >> "${LOG_FILE}" 2>&1
	fi
	print_timestamp "SYSBENCH (CORES = ${CURRENT_CORES}) STOP"
	sleep 15
}

export -f run_sysbench

function run_geekbench() {
	print_timestamp "GEEKBENCH (CORES = ${CURRENT_CORES}) START"
	taskset -c "${CURRENT_CORES}" "${GEEKBENCH_HOME}"/geekbench_x86_64 | tee -a "${LOG_FILE}"
	print_timestamp "GEEKBENCH (CORES = ${CURRENT_CORES}) STOP"
	sleep 15
}

export -f run_geekbench

function run_npb_omp_kernel() {
	local COMMAND="while true; do ${NPB_OMP_HOME}/${1} | tee -a ${LOG_FILE}; done"
	shift 1
	CORES_ARRAY=("$@")
	NUM_THREADS=1
	while [ "${NUM_THREADS}" -le "${THREADS}" ]
	do
      set_n_cores ${NUM_THREADS}
	    start_cpu_monitor
	    print_timestamp "NPB (CORES = ${CURRENT_CORES}) START"
	    export OMP_NUM_THREADS="${NUM_THREADS}"
	    taskset -c "${CURRENT_CORES}" timeout 5m bash -c "${COMMAND}"
	    print_timestamp "NPB (CORES = ${CURRENT_CORES}) STOP"
	    stop_cpu_monitor
	    NUM_THREADS=$(( NUM_THREADS * 2 ))
	    sleep 30
	done
}

export -f run_npb_omp_kernel

function run_npb_mpi_kernel() {
	local COMMAND=""
	local NPB_KERNEL=${1}
	shift 1
	CORES_ARRAY=("$@")
	BASE=1
	NUM_THREADS=$(( BASE * BASE ))
	while [ "${NUM_THREADS}" -le "${THREADS}" ]
	do
	    COMMAND="while true; do rm -f ${GLOBAL_HOME}/btio.epio.out*; mpirun -np ${NUM_THREADS} --bind-to none --mca btl ^openib ${NPB_MPI_HOME}/${NPB_KERNEL} | tee -a ${LOG_FILE}; done"
        set_n_cores ${NUM_THREADS}
	    start_cpu_monitor
	    print_timestamp "NPB (CORES = ${CURRENT_CORES}) START"
	    taskset -c "${CURRENT_CORES}" timeout 5m bash -c "${COMMAND}"
	    print_timestamp "NPB (CORES = ${CURRENT_CORES}) STOP"
	    stop_cpu_monitor
	    BASE=$(( BASE + 1))
	    NUM_THREADS=$(( BASE * BASE )) # BT I/O needs an square number of processes
	    sleep 30
	done
	rm -f "${GLOBAL_HOME}"/btio.epio.out* # Remove BT I/O generated files
}

export -f run_npb_mpi_kernel

function run_spark() {
  CORES_ARRAY=("$@")
	NUM_THREADS=1
	while [ "${NUM_THREADS}" -le "${THREADS}" ]
	do
		set_n_cores ${NUM_THREADS}
		start_cpu_monitor
		print_timestamp "SPARK (CORES = ${CURRENT_CORES}) START"
		taskset -c "${CURRENT_CORES}" "${SMUSKET_HOME}"/bin/smusketrun -sm "-i ${SPARK_DATA_DIR}/ERR031558.fastq -n 64 -k 25" --conf "spark.local.dir=${SPARK_DATA_DIR}" --master local["${NUM_THREADS}"] --driver-memory 200g
		print_timestamp "SPARK (CORES = ${CURRENT_CORES}) STOP"
		stop_cpu_monitor
		rm -rf "${SPARK_DATA_DIR}"/blockmgr* "${SPARK_DATA_DIR}"/spark-*
		NUM_THREADS=$(( NUM_THREADS * 2 ))
		sleep 20
	done
}

export -f run_spark

function run_fio() {
  CORES_ARRAY=("$@")
	NUM_THREADS=1
	MAX_THREADS=8
	while [ "${NUM_THREADS}" -le "${MAX_THREADS}" ]
	do
	  FIO_OPTIONS="--name=fio_job --directory=/tmp --bs=4k --size=10g --rw=randrw --iodepth=64 --numjobs=${NUM_THREADS} --runtime=30h --time_based"
		set_n_cores ${NUM_THREADS}
		start_cpu_monitor
		print_timestamp "FIO (CORES = ${CURRENT_CORES}) START"
    if [ "${OS_VIRT}" == "docker" ]; then
      docker run -d --rm --cpuset-cpus "${CURRENT_CORES}" --name fio -v "${FIO_TARGET}":/tmp ljishen/fio:latest ${FIO_OPTIONS}
    else
      sudo apptainer instance start --cpuset-cpus "${CURRENT_CORES}" -B "${FIO_TARGET}":/tmp "${FIO_HOME}"/fio.sif fio ${FIO_OPTIONS}
    fi
    sleep 300
		print_timestamp "FIO (CORES = ${CURRENT_CORES}) STOP"
    if [ "${OS_VIRT}" == "docker" ]; then
      docker stop fio
    else
      sudo apptainer instance stop fio
    fi
		stop_cpu_monitor
		rm -rf "${FIO_TARGET}"/fio_job*
		NUM_THREADS=$(( NUM_THREADS * 2 ))
		sleep 30
	done
}

export -f run_fio

function idle_cpu() {
	print_timestamp "IDLE START"
	sleep 30
	print_timestamp "IDLE STOP"
	sleep 5
}

export -f idle_cpu

function run_seq_experiment() {
  NAME=$1
  TEST_FUNCTION=$2
  CURRENT_CORES=$3

  local START_TEST=$(date +%s%N)

  # Start monitoring agent and move to current core
  start_cpu_monitor
  if [ -n "${CPU_MONITOR_PID}" ]; then
    taskset -cp "${CURRENT_CORES}" "${CPU_MONITOR_PID}"
    m_echo "Changed CPU monitor (pid = ${CPU_MONITOR_PID}) affinity to core ${CURRENT_CORES}"
  fi

  # Incrementally stress core
  LOAD=10
  while [ "${LOAD}" -le "100" ]; do
    # Stress CPU core
    "${TEST_FUNCTION}"
    # Increase load
    LOAD=$((LOAD + 10))
  done

  # Stop monitoring agent
  stop_cpu_monitor

  local END_TEST=$(date +%s%N)
  print_time "${START_TEST}" "${END_TEST}"
}

export -f run_seq_experiment

function run_experiment() {
  NAME=$1
  TEST_FUNCTION=$2
  shift 2
  CORES_ARRAY=("$@")

  CURRENT_CORES=""
  LOAD=100
  local START_TEST=$(date +%s%N)
  for ((i = 0; i < ${#CORES_ARRAY[@]}; i += 1)); do
    # Add new cores to the list
    if [ -z "${CURRENT_CORES}" ]; then
      CURRENT_CORES+="${CORES_ARRAY[i]}"
    else
      CURRENT_CORES+=",${CORES_ARRAY[i]}"
    fi
    # Start daemon to monitor CPU (usage, frequency,...)
    start_cpu_monitor
    # Run workload
    "${TEST_FUNCTION}"
    # Stop monitoring daemon
    stop_cpu_monitor
    # Increase load for next iteration
    LOAD=$((LOAD + 100))
  done
  local END_TEST=$(date +%s%N)
  print_time "${START_TEST}" "${END_TEST}"
}

export -f run_experiment
