#!/bin/bash

if [ "$OS_VIRT" == "docker" ]; then
	docker stop rapl glances
	docker rm rapl glances
else
	sudo apptainer instance stop rapl && sudo apptainer instance stop glances
fi

kill "${CPUFREQ_PID}"

if ps -p "${CPUFREQ_PID}" > /dev/null; then
   echo "Error while killing CPUfreq process"
else
   echo "CPUfreq process succesfully stopped"
fi