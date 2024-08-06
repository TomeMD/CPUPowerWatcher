#!/bin/bash

BASE_MEASURE_TIME=240

################################################################################################
# Only_RAPL: Get idle measurements only with RAPL monitor running (lowest possible overhead)
################################################################################################
TIMESTAMPS_FILE=${LOG_DIR}/idle.timestamps
NAME="ONLY_RAPL"
print_timestamp "IDLE START"
sleep "${BASE_MEASURE_TIME}"
print_timestamp "IDLE STOP"

################################################################################################
# Monitor_1_Core: Get idle measurements with RAPL and CPU monitor (1 core) running
################################################################################################
CURRENT_CORES="0"
TIMESTAMPS_FILE=${LOG_DIR}/idle.timestamps
NAME="MONITOR_1_CORE"

start_cpu_monitor
print_timestamp "IDLE START"
sleep "${BASE_MEASURE_TIME}"
print_timestamp "IDLE STOP"
stop_cpu_monitor

################################################################################################
# Monitor_All_Cores: Get idle measurements with RAPL and CPU monitor (all cores) running
################################################################################################
TIMESTAMPS_FILE=${LOG_DIR}/idle.timestamps
NAME="MONITOR_ALL_CORES"
CURRENT_CORES=""
for (( i=0; i<THREADS; i++ )); do
  if [ "$i" -ne 0 ]; then
    CURRENT_CORES+=","
  fi
  CURRENT_CORES+="${i}"
done

start_cpu_monitor
print_timestamp "IDLE START"
sleep "${BASE_MEASURE_TIME}"
print_timestamp "IDLE STOP"
stop_cpu_monitor