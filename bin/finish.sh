#!/usr/bin/env bash

m_echo "Closing environment"
if [ "${OS_VIRT}" == "docker" ]; then
  for INSTANCE in rapl cpumetrics stress_system fio fio_noise; do
    if docker ps -a --format '{{.Names}}' | grep -qw "${INSTANCE}"; then
      docker stop "${INSTANCE}"
      docker rm "${INSTANCE}"
    fi
  done
fi

if [ "${OS_VIRT}" == "apptainer" ]; then
  for INSTANCE in rapl cpumetrics stress_system fio fio_noise; do
    if sudo apptainer instance list "${INSTANCE}" | grep -qw "${INSTANCE}"; then
      sudo apptainer instance stop "${INSTANCE}"
    fi
  done
fi

if [ "${ADD_IO_NOISE}" -ne 0 ]; then
  rm -rf "${FIO_TARGET}"/fio_job*
fi

m_echo "Environment succesfully closed"