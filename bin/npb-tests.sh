#!/bin/bash

NAME=""
LOG_FILE=${LOG_DIR}/NPB.log
TIMESTAMPS_FILE=${LOG_DIR}/NPB.timestamps

CORES_PER_CPU=$(lscpu | grep "Core(s) per socket:" | awk '{print $4}')
SOCKETS=$(lscpu | grep "Socket(s):" | awk '{print $2}')
THREADS=$(($CORES_PER_CPU * $SOCKETS * 2))

START=$(date +%s%N)

sleep 30 # Initial wait

NAME="IS"
print_timestamp "NPB START"
for NUM_THREADS in $(seq 2 2 $THREADS)
do
    export OMP_NUM_THREADS=$NUM_THREADS
    for i in $(seq 1 60); do
		${NPB_HOME}/bin/is.C.x | tee -a $LOG_FILE
	done
done
print_timestamp "NPB STOP"

sleep 10

NAME="FT"
print_timestamp "NPB START"
for NUM_THREADS in $(seq 2 2 $THREADS)
do
	export OMP_NUM_THREADS=$NUM_THREADS
	for i in $(seq 1 5); do
		${NPB_HOME}/bin/ft.C.x | tee -a $LOG_FILE
	done
done
print_timestamp "NPB STOP"

sleep 10

NAME="MG"
print_timestamp "NPB START"
for NUM_THREADS in $(seq 2 2 $THREADS)
do
	export OMP_NUM_THREADS=$NUM_THREADS
	for i in $(seq 1 15); do
		${NPB_HOME}/bin/mg.C.x | tee -a $LOG_FILE
	done
done
print_timestamp "NPB STOP"

sleep 10

NAME="CG"
print_timestamp "NPB START"
for NUM_THREADS in $(seq 2 2 $THREADS)
do
	export OMP_NUM_THREADS=$NUM_THREADS
	for i in $(seq 1 5); do
		${NPB_HOME}/bin/cg.C.x | tee -a $LOG_FILE
	done
done
print_timestamp "NPB STOP"

sleep 10

NAME="BT"
print_timestamp "NPB START"
for NUM_THREADS in $(seq 2 2 $THREADS)
do
	export OMP_NUM_THREADS=$NUM_THREADS
	for i in $(seq 1 3); do
		${NPB_HOME}/bin/bt.C.x | tee -a $LOG_FILE
	done
done
print_timestamp "NPB STOP"

END=$(date +%s%N)
NAME="TOTAL"
print_time START END