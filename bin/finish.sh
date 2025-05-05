#!/usr/bin/env bash

m_echo "Closing environment"
if [ "${OS_VIRT}" == "docker" ]; then
  docker stop $(docker ps -a -q)
  docker rm $(docker ps -a -q)
fi

if [ "${OS_VIRT}" == "apptainer" ]; then
  sudo apptainer instance stop --all
fi

if [ "${ADD_IO_NOISE}" -ne 0 ]; then
  rm -rf "${FIO_TARGET}"/fio_job*
fi

m_echo "Environment succesfully closed"