#!/bin/bash

m_echo "Closing environment"
if [ "$OS_VIRT" == "docker" ]; then
	docker stop rapl glances
	docker rm rapl glances
else
	sudo apptainer instance stop rapl && sudo apptainer instance stop glances
fi

kill "${CPUFREQ_PID}"

if ps -p "${CPUFREQ_PID}" > /dev/null; then
   m_err "Error while killing CPUfreq process"
else
   m_echo "CPUfreq process succesfully stopped"
fi
m_echo "Environment succesfully stoped"