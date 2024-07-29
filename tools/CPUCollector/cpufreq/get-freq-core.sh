#!/bin/bash

if [ $# -ne 3 ]; then
  echo "Error: Missing some arguments"
  echo "Usage: $0 <CORES_LIST> <INFLUXDB_HOST> <INFLUXDB_BUCKET>"
  exit 1
fi

CORES_LIST=$1
IFS=',' read -ra CORES_ARRAY <<< "${CORES_LIST}"
INFLUXDB_HOST=$2
INFLUXDB_BUCKET=$3

while true; do
    SUM=0
    for CORE in "${CORES_ARRAY[@]}"; do
      FREQ=$(<"/sys/devices/system/cpu/cpu${CORE}/cpufreq/scaling_cur_freq")
      SUM=$((SUM + FREQ))
    done
    AVERAGE=$((SUM / ${#CORES_ARRAY[@]} / 1000))
    SUM=$((SUM / 1000))

    # Send data to InfluxDB
    TIMESTAMP=$(date +%s%N)
    DATA="cpu_frequency average=${AVERAGE},sum=${SUM} ${TIMESTAMP}"
    curl -s -XPOST "http://${INFLUXDB_HOST}:8086/api/v2/write?org=MyOrg&bucket=${INFLUXDB_BUCKET}" --header "Authorization: Token MyToken" --data-binary "${DATA}"
    sleep 1
done