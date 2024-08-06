#!/bin/bash

# Start monitoring environment
if [ "${OS_VIRT}" == "docker" ]; then
	docker run -d --name glances --pid host --privileged --network host --restart=unless-stopped -e GLANCES_OPT="-q --export influxdb2 --time 1" glances "${INFLUXDB_HOST}" "${INFLUXDB_BUCKET}"
	docker run -d --name rapl --pid host --privileged --network host --restart=unless-stopped rapl "${INFLUXDB_HOST}" "${INFLUXDB_BUCKET}"
else
    # TODO: Use nice to set lower priority to this process
    sudo apptainer instance start "${RAPL_HOME}"/rapl.sif rapl "${INFLUXDB_HOST}" "${INFLUXDB_BUCKET}"
fi


