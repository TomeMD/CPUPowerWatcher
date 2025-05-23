#!/usr/bin/env bash

###################################################################################################
# BASE MEASUREMENTS
# If --base was used, get base power measurements by only running RAPL daemon
###################################################################################################
if [ "${GET_BASE_MEASUREMENTS}" -ne "0" ]; then
  m_echo "Getting base measurements to know the overhead of the monitoring agents"
  . "${BIN_DIR}"/get-base-measurements.sh
fi

###################################################################################################
# MONITORING ENVIRONMENT INITIALIZATION
###################################################################################################
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

# Load workload functions
. "${BIN_DIR}"/load-workload-functions.sh

if [ "${CUSTOM_TESTS}" -ne "0" ]; then
  m_echo "Custom tests mode is active. Running custom tests from ${CUSTOM_TESTS_FILE}"
  . "${CUSTOM_TESTS_FILE}"
else
  m_echo "Running ${WORKLOAD} tests..."
  . "${BIN_DIR}/${WORKLOAD}/run-tests.sh"
fi