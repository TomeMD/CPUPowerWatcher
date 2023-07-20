#!/bin/bash

# Tools
export BIN_DIR=`dirname $0`/bin
export GLANCES_HOME=cpu_power_monitor/glances
export RAPL_HOME=cpu_power_monitor/rapl
export STRESS_HOME=stress-system/container
export NPB_HOME=${BIN_DIR}/NPB3.4.2/NPB3.4-OMP
export GEEKBENCH_HOME=${BIN_DIR}/Geekbench-${GEEKBENCH_VERSION}-Linux

# Logs
export LOG_DIR=${BIN_DIR}/../${OUTPUT_DIR}
export LOG_FILE=${LOG_DIR}/stress-system.log
export TIMESTAMPS_FILE=${LOG_DIR}/stress.timestamps

mkdir -p $LOG_DIR

# Start monitoring environment
if [ "$OS_VIRT" == "docker" ]; then
	docker run -d --name glances --pid host --privileged --network host --restart=unless-stopped -e GLANCES_OPT="-q --export influxdb2 --time 2" glances
	docker run -d --name rapl --pid host --privileged --network host --restart=unless-stopped rapl
else
	sudo apptainer instance start --env "GLANCES_OPT=-q --export influxdb2 --time 2" ${GLANCES_HOME}/glances.sif glances
	sudo apptainer instance start ${RAPL_HOME}/rapl.sif rapl
fi

# Load bash functions
. ${BIN_DIR}/functions.sh