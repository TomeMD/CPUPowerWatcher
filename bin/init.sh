#!/bin/bash

# Start monitoring environment
if [ "${OS_VIRT}" == "docker" ]; then
	docker run -d --name glances --pid host --privileged --network host --restart=unless-stopped -e GLANCES_OPT="-q --export influxdb2 --time 5" glances "${INFLUXDB_HOST}" "${INFLUXDB_BUCKET}"
	docker run -d --name rapl --pid host --privileged --network host --restart=unless-stopped rapl "${INFLUXDB_HOST}" "${INFLUXDB_BUCKET}"
else
	sudo apptainer instance start -B "${GLANCES_HOME}"/etc:/etc/glances --env "GLANCES_OPT=-q --export influxdb2 --time 2" "${GLANCES_HOME}"/glances.sif glances "${INFLUXDB_HOST}" "${INFLUXDB_BUCKET}"
	sudo apptainer instance start "${RAPL_HOME}"/rapl.sif rapl "${INFLUXDB_HOST}" "${INFLUXDB_BUCKET}"
fi

if [ "${RUN_FIO}" -ne 0 ]; then
  FIO_OPTIONS="--name=fio_job --directory=/tmp --bs=4k --size=10g --rw=randrw --numjobs=1"
  if [ "${OS_VIRT}" == "docker" ]; then
    echo "docker run --name fio -d -v ${FIO_TARGET}:/tmp fio ${FIO_OPTIONS}"
    docker run -d --name fio -v "${FIO_TARGET}":/tmp fio ${FIO_OPTIONS}
  else
    sudo apptainer instance start -B "${FIO_TARGET}":/tmp "${FIO_HOME}"/fio.sif fio ${FIO_OPTIONS}
  fi
fi
