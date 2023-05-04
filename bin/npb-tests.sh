#!/bin/bash

NAME=""
LOG_FILE=${LOG_DIR}/NPB.log
TIMESTAMPS_FILE=${LOG_DIR}/NPB.timestamps

START=$(date +%s%N)

sleep 30 # Initial wait

NAME="CG"
print_timestamp "NPB START"
${NPB_HOME}/bin/cg.C.x | tee -a $LOG_FILE
print_timestamp "NPB STOP"

sleep 10

NAME="FT"
print_timestamp "NPB START"
${NPB_HOME}/bin/ft.C.x | tee -a $LOG_FILE
print_timestamp "NPB STOP"

sleep 10

NAME="MG"
print_timestamp "NPB START"
${NPB_HOME}/bin/mg.C.x | tee -a $LOG_FILE
print_timestamp "NPB STOP"

sleep 10

NAME="BT"
print_timestamp "NPB START"
${NPB_HOME}/bin/bt.C.x | tee -a $LOG_FILE
print_timestamp "NPB STOP"

END=$(date +%s%N)
NAME="TOTAL"
print_time START END