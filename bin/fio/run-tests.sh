#!/usr/bin/env bash

STR_LIST=$(get_comma_separated_list 0 "${THREADS}")
IFS=',' read -ra SEQUENTIAL_CORES <<< "${STR_LIST}"

# Initial wait
sleep 30

START=$(date +%s%N)

NAME="STRESS-IO"
TIMESTAMPS_FILE=${LOG_DIR}/fio.timestamps
run_fio "${SEQUENTIAL_CORES[@]}"

END=$(date +%s%N)
NAME="TOTAL"
print_time START END