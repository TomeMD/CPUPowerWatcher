#!/bin/bash

# Tools
export BIN_DIR=`dirname $0`/bin
export GLANCES_HOME=${BIN_DIR}/glances_influxdb_grafana/glances
export RAPL_HOME=${BIN_DIR}/glances_influxdb_grafana/rapl
export STRESS_HOME=${BIN_DIR}/stress-system/container
export NPB_HOME=${BIN_DIR}/NPB3.4.2/NPB3.4-OMP

# Logs
export LOG_DIR=${BIN_DIR}/../${OUTPUT_DIR}
export LOG_FILE=${LOG_DIR}/stress-system.log
export TIMESTAMPS_FILE=${LOG_DIR}/stress.timestamps

mkdir -p $LOG_DIR

# Start monitoring environment
if [ "$USE_DOCKER" -eq "0" ]; then
	docker run -d --name glances --pid host --privileged --network host --restart=unless-stopped -e GLANCES_OPT="-q --export influxdb2 --time 2" -v $(pwd)/${GLANCES_HOME}/etc/glances.conf:/glances/conf/glances.conf glances
	sleep 6
	docker run -d --name rapl --pid host --privileged --network host --restart=unless-stopped rapl
else
	sudo apptainer instance start --env "GLANCES_OPT=-q --export influxdb2 --time 2" --bind ${GLANCES_HOME}/etc/glances.conf:/glances/conf/glances.conf ${GLANCES_HOME}/glances.sif glances
	sleep 6
	sudo apptainer instance start ${RAPL_HOME}/rapl.sif rapl
fi

# Load bash functions
. ${BIN_DIR}/functions.sh