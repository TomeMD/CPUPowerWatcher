#!/bin/bash

if [ $# -eq 0 ]; then
  echo "Cores list not specified. Aborting..."
  exit 1
fi

CORES_LIST=$1
IFS=',' read -ra CORES_ARRAY <<< "${CORES_LIST}"

while true; do
    SUM=0
    for CORE in "${CORES_ARRAY[@]}"; do
      FREQ=$(<"/sys/devices/system/cpu/cpu${CORE}/cpufreq/scaling_cur_freq")
      SUM=$((SUM + FREQ))
    done
    AVERAGE=$((SUM / ${#CORES_ARRAY[@]} / 1000))

    # Send data to InfluxDB
    TIMESTAMP=$(date +%s%N)
    DATA="cpu_frequency average=${AVERAGE},sum=${SUM} ${TIMESTAMP}"
    curl -s -XPOST "http://montoxo.des.udc.es:8086/api/v2/write?org=MyOrg&bucket=glances" --header "Authorization: Token MyToken" --data-binary "${DATA}"
    sleep 1
done