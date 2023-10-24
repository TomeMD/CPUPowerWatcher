#!/bin/bash

# Start monitoring environment
if [ "$OS_VIRT" == "docker" ]; then
	docker run -d --name glances --pid host --privileged --network host --restart=unless-stopped -e GLANCES_OPT="-q --export influxdb2 --time 2" glances "${INFLUXDB_HOST}" "${INFLUXDB_BUCKET}"
	docker run -d --name rapl --pid host --privileged --network host --restart=unless-stopped rapl "${INFLUXDB_HOST}" "${INFLUXDB_BUCKET}"
else
	sudo apptainer instance start --env "GLANCES_OPT=-q --export influxdb2 --time 2" "${GLANCES_HOME}"/glances.sif glances "${INFLUXDB_HOST}" "${INFLUXDB_BUCKET}"
	sudo apptainer instance start "${RAPL_HOME}"/rapl.sif rapl "${INFLUXDB_HOST}" "${INFLUXDB_BUCKET}"
fi

if [ "${WORKLOAD}" == "spark" ]; then
  m_echo "Start Spark Master node"
  "${SPARK_HOME}"/sbin/start-master.sh
fi