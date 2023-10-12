#!/bin/bash

# Start monitoring environment
if [ "$OS_VIRT" == "docker" ]; then
	docker run -d --name glances --pid host --privileged --network host --restart=unless-stopped -e GLANCES_OPT="-q --export influxdb2 --time 2" glances
	docker run -d --name rapl --pid host --privileged --network host --restart=unless-stopped rapl
else
	sudo apptainer instance start --env "GLANCES_OPT=-q --export influxdb2 --time 2" "${GLANCES_HOME}"/glances.sif glances
	sudo apptainer instance start "${RAPL_HOME}"/rapl.sif rapl
fi

if [ "${WORKLOAD}" == "spark" ]; then
  m_echo "Start Spark Master node"
  "${SPARK_HOME}"/sbin/start-master.sh
fi