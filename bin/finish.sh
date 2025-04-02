#!/bin/bash

m_echo "Closing environment"
if [ "$OS_VIRT" == "docker" ]; then
  docker stop $(docker ps -a -q)
  docker rm $(docker ps -a -q)
else
  sudo apptainer instance stop rapl --all
fi

if [ "${ADD_IO_NOISE}" -ne 0 ]; then
  rm -rf "${FIO_TARGET}"/fio_job*
fi

m_echo "Environment succesfully closed"