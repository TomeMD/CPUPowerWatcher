#!/bin/bash

CORES_PER_CPU=$(lscpu | grep "Core(s) per socket:" | awk '{print $4}')
PAIRS_OF_CORES=$(($CORES_PER_CPU / 2))  # X cores form X/2 pairs of cores

# Start tests
START=$(date +%s%N)

sleep 30 # Initial wait

#run_experiment <NAME> <CORES_PER_CPU> <TOTAL_PAIRS> <PAIR_OFFSET> <INCREMENT> <CPU_SWITCH>
################################################################################################
# Only_P: Only physical cores in order
################################################################################################
TIMESTAMPS_FILE=${LOG_DIR}/Only_P.timestamps
run_experiment "Only_P" $CORES_PER_CPU $PAIRS_OF_CORES 1 2 0 "stress_cpu"

################################################################################################
# Test_P&L: Load by pairs of physical and logical cores
################################################################################################
TIMESTAMPS_FILE=${LOG_DIR}/Test_P_and_L.timestamps
run_experiment "Test_P&L" $CORES_PER_CPU $(($PAIRS_OF_CORES * 2)) $CORES_PER_CPU 1 0 "stress_cpu"

################################################################################################
# Test_1P_2L: First physical cores, then logical cores.
################################################################################################
TIMESTAMPS_FILE=${LOG_DIR}/Test_1P_2L.timestamps
run_experiment "Test_1P_2L" $CORES_PER_CPU $(($PAIRS_OF_CORES * 2)) 1 2 0 "stress_cpu"

################################################################################################
END=$(date +%s%N)
NAME="TOTAL"
print_time START END