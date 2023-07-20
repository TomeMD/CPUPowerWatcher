#!/bin/bash

while true; do
  CPU_FREQ=$(($(cpufreq-info -f) / 1000)) # Frequency in MHz
  TIMESTAMP=$(date +%s%N)
  DATA="cpu_frequency value=${CPU_FREQ} ${TIMESTAMP}"
  curl -i -XPOST "http://montoxo.des.udc.es:8086/api/v2/write?org=MyOrg&bucket=glances" --header "Authorization: Token MyToken" --data-binary "${DATA}"
  sleep 2
done