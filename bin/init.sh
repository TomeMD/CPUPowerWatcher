#!/bin/bash

# Tools


# Logs
export LOG_DIR=${BIN_DIR}/../${OUTPUT_DIR}
export LOG_FILE=${LOG_DIR}/stress-system.log
export TIMESTAMPS_FILE=${LOG_DIR}/stress.timestamps

mkdir -p $LOG_DIR

# Start monitoring environment
if [ "$OS_VIRT" == "docker" ]; then
	docker run -d --name glances --pid host --privileged --network host --restart=unless-stopped -e GLANCES_OPT="-q --export influxdb2 --time 2" glances
	docker run -d --name cpufreq --pid host --privileged --network host --restart=unless-stopped cpufreq
	docker run -d --name rapl --pid host --privileged --network host --restart=unless-stopped rapl
else
	sudo apptainer instance start --env "GLANCES_OPT=-q --export influxdb2 --time 2" ${GLANCES_HOME}/glances.sif glances
	sudo apptainer instance start ${CPUFREQ_HOME}/cpufreq.sif cpufreq
	sudo apptainer instance start ${RAPL_HOME}/rapl.sif rapl
fi

# Load bash functions
. ${BIN_DIR}/functions.sh