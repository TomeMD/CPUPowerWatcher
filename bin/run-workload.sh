#!/usr/bin/env bash

if [ "${GET_BASE_MEASUREMENTS}" -ne "0" ]; then
  m_echo "Getting base measurements to know the overhead of the monitoring agents"
  . "${TEST_DIR}"/get-base-measurements.sh
fi

# Initialize monitoring environment
. "${BIN_DIR}"/init.sh

# Add an extra container running fio to add I/O noise in the observed metrics
if [ "${ADD_IO_NOISE}" -ne "0" ]; then
  FIO_OPTIONS="--name=fio_job --directory=/tmp --bs=4k --size=10g --rw=randrw --numjobs=1 --runtime=30h --time_based"
  if [ "${OS_VIRT}" == "docker" ]; then
    docker run -d --cpuset-cpus "0" --name fio_noise --pid host --privileged --network host --restart=unless-stopped -v "${FIO_TARGET}":/tmp ljishen/fio:latest ${FIO_OPTIONS}
  else
    sudo apptainer instance start --cpuset-cpus "0" -B "${FIO_TARGET}":/tmp "${FIO_HOME}"/fio.sif fio_noise ${FIO_OPTIONS}
  fi
fi

m_echo "Running ${WORKLOAD} tests..."

if [ "${CUSTOM_TESTS}" -ne "0" ];then
  m_echo "Custom tests mode is active. Running custom tests from ${CUSTOM_TESTS_FILE}"
  . "${CUSTOM_TESTS_FILE}"
elif [ "${WORKLOAD}" == "npb" ]; then
  . "${TEST_DIR}"/npb-tests.sh
elif [ "${WORKLOAD}" == "spark" ]; then
  . "${TEST_DIR}"/spark-tests.sh
elif [ "${WORKLOAD}" == "fio" ]; then
  . "${TEST_DIR}"/fio-tests.sh
elif [ "${WORKLOAD}" == "stress-system" ]; then

  # Set parameters for the specified pattern
  if [ "${STRESS_PATTERN}" = "stairs-up" ]; then # <INITIAL_LOAD> <LOAD_JUMP>
    # Start at 10 and increase by 10 at each step
    export SINGLE_CORE_PARAMETERS=("10" "10")
    # Start at 100 (one core) and increase by 100 at each step
    export PARAMETERS=("100" "100")

  elif [ "${STRESS_PATTERN}" = "stairs-down" ]; then # <INITIAL_LOAD> <LOAD_JUMP>
    # Start at 100 (one core) and decrease by 10 at each step
    export SINGLE_CORE_PARAMETERS=("100" "10")
    # Start at maximum and decrease by 100 (one core) at each step
    export PARAMETERS=("${MAX_SUPPORTED_LOAD}" "100")

  elif [ "${STRESS_PATTERN}" = "zigzag" ]; then # <INITIAL_LOAD> <INITIAL_JUMP> <JUMP_DECREASE> <INITIAL_DIRECTION>
    # Start at 100, decrease 90 to 10, increase 80 to 90, decrease 70 to 20...
    export SINGLE_CORE_PARAMETERS=("100" "90" "10" "0")
    # Start at maximum, decrease 'maximum - 100' to 100, increase 'maximum - 200' to 'maximum - 100'...
    export PARAMETERS=("${MAX_SUPPORTED_LOAD}" "$((MAX_SUPPORTED_LOAD - 100))" "100" "0")
  fi

  # Run different tests for single-socket CPUs and multi-socket CPUs
  if [ "${SOCKETS}" -eq "1" ]; then
    . "${TEST_DIR}"/tests-singlesocket.sh
  elif [ "${SOCKETS}" -eq "2" ]; then
    . "${TEST_DIR}"/tests-multisocket.sh
  else
    m_echo "Number of sockets (${SOCKETS}) not supported"
    m_echo "Aborting tests..."
  fi
fi