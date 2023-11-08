#!/bin/bash

CORES_PER_CPU=$(lscpu | grep "Core(s) per socket:" | awk '{print $4}')
SOCKETS=$(lscpu | grep "Socket(s):" | awk '{print $2}')
export THREADS=$((CORES_PER_CPU * SOCKETS * 2))

START=$(date +%s%N)

sleep 30 # Initial wait

NAME="SMUSKET"
TIMESTAMPS_FILE=${LOG_DIR}/Spark_Smusket.timestamps
run_spark

END=$(date +%s%N)
NAME="TOTAL"
print_time START END