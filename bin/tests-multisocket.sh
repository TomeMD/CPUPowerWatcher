#!/bin/bash

PAIRS_OF_PHY_CORES=$PHY_CORES_PER_CPU # The are 2 CPUs with PHY_CORES_PER_CPU cores each
PAIRS_OF_CORES=$((PAIRS_OF_PHY_CORES * 2)) # With logical cores total pairs of cores multiply by 2

# Start tests
START=$(date +%s%N)

sleep 30 # Initial wait

# Used CPUs are named first CPU0 phy cores, then CPU1 phy cores, then CPU0 logical cores...
#run_experiment <NAME> <TOTAL_PAIRS> <PAIR_OFFSET> <INCREMENT> <CPU_SWITCH> <TEST_FUNCTION>
################################################################################################
# Group_P: First CPU0 physical cores, then CPU1 physical cores
################################################################################################
TIMESTAMPS_FILE=${LOG_DIR}/Group_P.timestamps
run_experiment "Group_P" "${PAIRS_OF_PHY_CORES}" 1 2 0 "run_${WORKLOAD}"

################################################################################################
# Spread_P: Switching CPU cores, 2 cores from CPU0, then 2 cores from CPU1, then 2 from CPU0...
################################################################################################
TIMESTAMPS_FILE=${LOG_DIR}/Spread_P.timestamps
run_experiment "Spread_P" "${PAIRS_OF_PHY_CORES}" 1 2 1 "run_${WORKLOAD}"

################################################################################################
# Group_P&L: Load by pairs of physical and logical cores, first CPU0, then CPU1.
################################################################################################
TIMESTAMPS_FILE=${LOG_DIR}/Group_P_and_L.timestamps
run_experiment "Group_P&L" "${PAIRS_OF_CORES}" $((PHY_CORES_PER_CPU * 2)) 1 0 "run_${WORKLOAD}"

################################################################################################
# Group_1P_2L: First physical cores, then logical cores. First load CPU0 until all physical and 
# logical cores are loaded at 100%, then do the same with CPU1.
################################################################################################
TIMESTAMPS_FILE=${LOG_DIR}/Group_1P_2L.timestamps
run_experiment "Group_1P_2L" "${PAIRS_OF_CORES}" 1 2 $((PHY_CORES_PER_CPU / 2)) "run_${WORKLOAD}"

################################################################################################
# Spread_P&L: Load by pairs switching CPUs. One pair (physical core + logical core) from CPU0, 
# then from CPU1, then from CPU0...
################################################################################################
TIMESTAMPS_FILE=${LOG_DIR}/Spread_P_and_L.timestamps
run_experiment "Spread_P&L" "${PAIRS_OF_CORES}" $((PHY_CORES_PER_CPU * 2)) 1 1 "run_${WORKLOAD}"

################################################################################################
END=$(date +%s%N)
NAME="TOTAL"
print_time START END