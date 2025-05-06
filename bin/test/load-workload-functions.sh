#!/usr/bin/env bash

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

function run_stress-system() {
    local CPU_QUOTA=$(echo "scale=2; ${LOAD} / 100 " | bc)
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

    # Run stress-system using the appropiate container engine
	print_timestamp "STRESS-TEST (CORES = ${CURRENT_CORES}) START"
	if [ "${OLD_LOAD}" -ge "1" ]; then
      if [ "${OS_VIRT}" == "docker" ]; then
          m_echo "docker run --rm --name stress-system -v ${STRESS_REPORTS_DIR}:/opt ${CONTAINER_OPTS} -it stress-system ${STRESS_OPTS}"
        docker run --rm --name stress-system -v "${STRESS_REPORTS_DIR}:/opt" ${CONTAINER_OPTS} -it stress-system ${STRESS_OPTS} >> "${LOG_FILE}" 2>&1
      else
          m_echo "sudo apptainer instance start -B ${STRESS_REPORTS_DIR}:/opt ${CONTAINER_OPTS} ${STRESS_CONTAINER_DIR}/stress.sif stress_system ${STRESS_OPTS}"
        sudo apptainer instance start -B "${STRESS_REPORTS_DIR}:/opt" ${CONTAINER_OPTS} "${STRESS_CONTAINER_DIR}/stress.sif" stress_system ${STRESS_OPTS} >> "${LOG_FILE}" 2>&1
      fi
    fi

	sleep "${STRESS_TIME}"

	# Apptainer requires using instances to apply CPU constraints, thus an instance must be deployed and destroyed
	if [ "${OLD_LOAD}" -ge "1" ] && [ "${OS_VIRT}" == "apptainer" ]; then
      sudo apptainer instance stop stress_system
	fi
	print_timestamp "STRESS-TEST (CORES = ${CURRENT_CORES}) STOP"

	# Reset LOAD to its original value
	LOAD="${OLD_LOAD}"

	sleep "${IDLE_TIME}"
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
	    # start_cpu_monitor
	    print_timestamp "NPB (CORES = ${CURRENT_CORES}) START"
	    export OMP_NUM_THREADS="${NUM_THREADS}"
	    taskset -c "${CURRENT_CORES}" timeout 5m bash -c "${COMMAND}"
	    print_timestamp "NPB (CORES = ${CURRENT_CORES}) STOP"
	    # stop_cpu_monitor
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
	    # start_cpu_monitor
	    print_timestamp "NPB (CORES = ${CURRENT_CORES}) START"
	    taskset -c "${CURRENT_CORES}" timeout 5m bash -c "${COMMAND}"
	    print_timestamp "NPB (CORES = ${CURRENT_CORES}) STOP"
	    # stop_cpu_monitor
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
		# start_cpu_monitor
		print_timestamp "SPARK (CORES = ${CURRENT_CORES}) START"
		taskset -c "${CURRENT_CORES}" "${SMUSKET_HOME}"/bin/smusketrun -sm "-i ${SPARK_DATA_DIR}/ERR031558.fastq -n 64 -k 25" --conf "spark.local.dir=${SPARK_DATA_DIR}" --master local["${NUM_THREADS}"] --driver-memory 200g
		print_timestamp "SPARK (CORES = ${CURRENT_CORES}) STOP"
		# stop_cpu_monitor
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
  while [ "${NUM_THREADS}" -le "${MAX_THREADS}" ]; do
    FIO_OPTIONS="--name=fio_job --directory=/tmp --bs=4k --size=10g --rw=randrw --iodepth=64 --numjobs=${NUM_THREADS} --runtime=30h --time_based"
    set_n_cores ${NUM_THREADS}
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
    rm -rf "${FIO_TARGET}"/fio_job*
    NUM_THREADS=$(( NUM_THREADS * 2 ))
    sleep 30
  done
}

export -f run_fio