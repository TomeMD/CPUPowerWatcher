#!/bin/bash

FULL_CORES_LIST=$(get_comma_separated_list 0 "${THREADS}")

# Start monitoring environment
if [ "${OS_VIRT}" == "docker" ]; then
    # TODO: Limit cpuset and cpu quota in Docker
	docker run -d --name rapl --pid host --privileged --network host --restart=unless-stopped rapl "${INFLUXDB_HOST}" "${INFLUXDB_BUCKET}"
	docker run -d --name cpumetrics --pid host --privileged --network host --restart=unless-stopped cpumetrics "${FULL_CORES_LIST}" "${INFLUXDB_HOST}" "${INFLUXDB_BUCKET}"
else
    sudo apptainer instance start --cpuset-cpus "0" --cpus 0.01 "${RAPL_HOME}"/rapl.sif rapl "${INFLUXDB_HOST}" "${INFLUXDB_BUCKET}"
    sudo apptainer instance start --cpuset-cpus "0" --cpus 0.10 "${CPU_MONITOR_HOME}"/cpumetrics.sif cpumetrics "${FULL_CORES_LIST}" "${INFLUXDB_HOST}" "${INFLUXDB_BUCKET}"
fi


