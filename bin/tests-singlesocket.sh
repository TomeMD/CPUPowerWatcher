#!/bin/bash

PAIRS_OF_PHY_CORES=$((PHY_CORES_PER_CPU / 2))  # X cores form X/2 pairs of cores
PAIRS_OF_CORES="${PHY_CORES_PER_CPU}" # With logical cores total pairs of cores multiply by 2

# Start tests
START=$(date +%s%N)

sleep 30 # Initial wait

#run_experiment <NAME> <TOTAL_PAIRS> <PAIR_OFFSET> <INCREMENT> <CPU_SWITCH> <TEST_FUNCTION>
################################################################################################
# Only_P: Only physical cores in order
################################################################################################
TIMESTAMPS_FILE=${LOG_DIR}/Only_P.timestamps
run_experiment "Only_P" "${PAIRS_OF_PHY_CORES}" 1 2 0 "run_${WORKLOAD}"

################################################################################################
# Test_P&L: Load by pairs of physical and logical cores
################################################################################################
TIMESTAMPS_FILE=${LOG_DIR}/Test_P_and_L.timestamps
run_experiment "Test_P&L" "${PAIRS_OF_CORES}" "${PHY_CORES_PER_CPU}" 1 0 "run_${WORKLOAD}"

################################################################################################
# Test_1P_2L: First physical cores, then logical cores.
################################################################################################
TIMESTAMPS_FILE=${LOG_DIR}/Test_1P_2L.timestamps
run_experiment "Test_1P_2L" "${PAIRS_OF_CORES}" 1 2 0 "run_${WORKLOAD}"

################################################################################################
END=$(date +%s%N)
NAME="TOTAL"
print_time START END