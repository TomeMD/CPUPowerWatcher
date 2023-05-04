#!/bin/bash

if [ "$USE_DOCKER" -eq "0" ]; then
	docker stop rapl glances
	docker rm rapl glances
else
	sudo apptainer instance stop rapl && sudo apptainer instance stop glances
fi

#rm -rf ${BIN_DIR}/glances_influxdb_grafana
#rm -rf ${BIN_DIR}/stress-system