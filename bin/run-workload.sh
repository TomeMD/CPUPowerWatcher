#!/bin/bash

if [ "${GET_BASE_MEASUREMENTS}" -ne "0" ]; then
  m_echo "Getting base measurements to know the overhead of the monitoring agents"
  . "${TEST_DIR}"/get-base-measurements.sh
fi

# Initialize monitoring environment (just RAPL currently)
. "${BIN_DIR}"/init.sh

if [ "${ADD_IO_NOISE}" -ne "0" ] && [ "${SINGLE_CORE_MODE}" -eq "0" ]; then
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
elif [ "${SINGLE_CORE_MODE}" -ne "0" ]; then
  m_echo "Single core mode is active. Running stress-system on 1 core (physical and logical)..."
  . "${TEST_DIR}"/tests-singlecore.sh
elif [ "${WORKLOAD}" == "npb" ]; then
  . "${TEST_DIR}"/npb-tests.sh
elif [ "${WORKLOAD}" == "spark" ]; then
  . "${TEST_DIR}"/spark-tests.sh
elif [ "${WORKLOAD}" == "fio" ]; then
  . "${TEST_DIR}"/fio-tests.sh
else
  if [ "${SOCKETS}" -eq "1" ]; then
    . "${TEST_DIR}"/tests-singlesocket.sh
  elif [ "${SOCKETS}" -eq "2" ]; then
    . "${TEST_DIR}"/tests-multisocket.sh
  else
    m_echo "Number of sockets (${SOCKETS}) not supported"
    m_echo "Aborting tests..."
  fi
fi