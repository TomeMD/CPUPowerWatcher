#!/bin/bash

. "${TEST_DIR}"/get-cores-lists-multisocket.sh

# Initial wait
sleep 30

# Start tests
START=$(date +%s%N)

################################################################################################
# Group_P: Only physical cores, one CPU at a time.
################################################################################################
TIMESTAMPS_FILE=${LOG_DIR}/Group_P.timestamps
run_experiment "Group_P" "run_${WORKLOAD}" "${GROUP_P_CORES[@]}"

################################################################################################
# Spread_P: Only physical cores, alternating between CPUs.
################################################################################################
TIMESTAMPS_FILE=${LOG_DIR}/Spread_P.timestamps
run_experiment "Spread_P" "run_${WORKLOAD}" "${SPREAD_P_CORES[@]}"

################################################################################################
# Group_P&L: Pairs of physical and logical cores, one CPU at a time.
################################################################################################
TIMESTAMPS_FILE=${LOG_DIR}/Group_P_and_L.timestamps
run_experiment "Group_P&L" "run_${WORKLOAD}" "${GROUP_P_AND_L_CORES[@]}"

################################################################################################
# Group_1P_2L: Physical cores first, then logical cores, one CPU at a time.
################################################################################################
TIMESTAMPS_FILE=${LOG_DIR}/Group_1P_2L.timestamps
run_experiment "Group_1P_2L" "run_${WORKLOAD}" "${GROUP_1P_2L_CORES[@]}"

################################################################################################
# Group_PP_LL: Physical cores first, one CPU at a time, then logical cores.
################################################################################################
TIMESTAMPS_FILE=${LOG_DIR}/Group_PP_LL.timestamps
run_experiment "Group_PP_LL" "run_${WORKLOAD}" "${GROUP_PP_LL_CORES[@]}"

################################################################################################
# Spread_P&L: Pairs of physical and logical cores, alternating between CPUs.
################################################################################################
TIMESTAMPS_FILE=${LOG_DIR}/Spread_P_and_L.timestamps
run_experiment "Spread_P&L" "run_${WORKLOAD}" "${SPREAD_P_AND_L_CORES[@]}"

################################################################################################
# Spread_PP_LL: Physical cores first, alternating between CPUs, then logical cores.
################################################################################################
TIMESTAMPS_FILE=${LOG_DIR}/Spread_PP_LL.timestamps
run_experiment "Spread_PP_LL" "run_${WORKLOAD}" "${SPREAD_PP_LL_CORES[@]}"

################################################################################################
END=$(date +%s%N)
NAME="TOTAL"
print_time START END