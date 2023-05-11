#!/bin/bash

NAME=""
LOG_FILE=${LOG_DIR}/NPB.log
TIMESTAMPS_FILE=${LOG_DIR}/NPB.timestamps

CORES_PER_CPU=$(lscpu | grep "Core(s) per socket:" | awk '{print $4}')
SOCKETS=$(lscpu | grep "Socket(s):" | awk '{print $2}')
export THREADS=$(($CORES_PER_CPU * $SOCKETS * 2))

START=$(date +%s%N)

sleep 30 # Initial wait

NAME="IS"
run_npb_kernel "bin/is.C.x"

sleep 10

NAME="FT"
run_npb_kernel "bin/ft.C.x"

sleep 10

NAME="MG"
run_npb_kernel "bin/mg.C.x"

sleep 10

NAME="CG"
run_npb_kernel "bin/cg.C.x"

sleep 10

NAME="BT"
run_npb_kernel "bin/bt.C.x"

END=$(date +%s%N)
NAME="TOTAL"
print_time START END