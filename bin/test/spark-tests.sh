#!/bin/bash

STR_LIST=$(get_comma_separated_list 0 "${THREADS}")
IFS=',' read -ra SEQUENTIAL_CORES <<< "${STR_LIST}"

# Initial wait
sleep 30

START=$(date +%s%N)

NAME="SMUSKET"
TIMESTAMPS_FILE=${LOG_DIR}/Spark_Smusket.timestamps
run_spark "${SEQUENTIAL_CORES[@]}"

END=$(date +%s%N)
NAME="TOTAL"
print_time START END