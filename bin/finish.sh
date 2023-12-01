#!/bin/bash

m_echo "Closing environment"
if [ "$OS_VIRT" == "docker" ]; then
	docker stop rapl glances
	docker rm rapl glances
else
	sudo apptainer instance stop rapl && sudo apptainer instance stop glances
fi

if [ "${ADD_IO_NOISE}" -ne 0 ]; then
  if [ "${OS_VIRT}" == "docker" ]; then
    docker stop fio
    docker rm fio
  else
    sudo apptainer instance stop fio
  fi
  rm -rf "${FIO_TARGET}"/fio_job*
fi

m_echo "Environment succesfully closed"