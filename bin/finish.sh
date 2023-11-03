#!/bin/bash

m_echo "Closing environment"
if [ "$OS_VIRT" == "docker" ]; then
	docker stop rapl glances
	docker rm rapl glances
else
	sudo apptainer instance stop rapl && sudo apptainer instance stop glances
fi

if [ "${RUN_FIO}" -ne 0 ]; then
  if [ "${OS_VIRT}" == "docker" ]; then
    docker stop fio
    docker rm fio
  else
    sudo apptainer instance stop fio
  fi
fi

if [ "${WORKLOAD}" == "spark" ]; then
  m_echo "Stop Spark Master node"
  "${SPARK_HOME}"/sbin/stop-master.sh
fi

m_echo "Environment succesfully closed"