#!/usr/bin/env bash

# Load core distributions for single-socket CPUs
. "${TEST_DIR}"/get-cores-lists-singlesocket.sh

# Initial wait
sleep 30

# Start tests
START=$(date +%s%N)

################################################################################################
# Single_Core: Stress a single core
################################################################################################
TIMESTAMPS_FILE=${LOG_DIR}/Single_Core.timestamps
"run_${STRESS_PATTERN}" "Single_Core" "run_${WORKLOAD}" "${SINGLE_CORE_PARAMETERS[@]}" "0"

################################################################################################
# Group_P: Only physical cores.
################################################################################################
TIMESTAMPS_FILE=${LOG_DIR}/Group_P.timestamps
"run_${STRESS_PATTERN}" "Group_P" "run_${WORKLOAD}" "${PARAMETERS[@]}" "${GROUP_P_CORES[@]}"

################################################################################################
# Group_P&L: Pairs of physical and logical cores.
################################################################################################
TIMESTAMPS_FILE=${LOG_DIR}/Group_P_and_L.timestamps
"run_${STRESS_PATTERN}" "Group_P&L" "run_${WORKLOAD}" "${PARAMETERS[@]}" "${GROUP_P_AND_L_CORES[@]}"

################################################################################################
# Group_1P_2L: Physical cores first, then logical cores.
################################################################################################
TIMESTAMPS_FILE=${LOG_DIR}/Group_1P_2L.timestamps
"run_${STRESS_PATTERN}" "Group_1P_2L" "run_${WORKLOAD}" "${PARAMETERS[@]}" "${GROUP_1P_2L_CORES[@]}"

################################################################################################
END=$(date +%s%N)
NAME="TOTAL"
print_time START END