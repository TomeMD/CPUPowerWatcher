#!/usr/bin/env bash
# Custom tests file to stress only each socket separated from a multisocket server with 2 CPUs
# Core numbering of the target server is:
#   0-15 physical cores CPU0
#   16-31 physical cores CPU1
#   32-47 logical cores CPU0
#   48-63 logical cores CPU1

# Initial wait
sleep 30

# Start tests
START=$(date +%s%N)

################################################################################################
# CPU0_Single_Core: Stress a single core from CPU0
################################################################################################
TIMESTAMPS_FILE=${LOG_DIR}/CPU0_Single_Core.timestamps
"run_${STRESS_PATTERN}" "CPU0_Single_Core" "run_${WORKLOAD}" "${SINGLE_CORE_PARAMETERS[@]}" "0"

################################################################################################
# CPU0_P&L: Load by pairs of physical and logical cores from CPU0
################################################################################################
TIMESTAMPS_FILE=${LOG_DIR}/CPU0_P_and_L.timestamps
CORES_ARRAY=("0" "32" "1" "33" "2" "34" "3" "35" "4" "36" "5" "37" "6" "38" "7" "39" "8" "40" "9" "41" "10" "42" "11" "43" "12" "44" "13" "45" "14" "46" "15" "47")
"run_${STRESS_PATTERN}" "CPU0_P&L" "run_${WORKLOAD}" "${PARAMETERS[@]}" "${CORES_ARRAY[@]}"

################################################################################################
# CPU0_1P_2L: First CPU0 physical cores, then CPU0 logical cores.
################################################################################################
CORES_ARRAY=("0" "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" "11" "12" "13" "14" "15" "32" "33" "34" "35" "36" "37" "38" "39" "40" "41" "42" "43" "44" "45" "46" "47")
TIMESTAMPS_FILE=${LOG_DIR}/CPU0_1P_2L.timestamps
"run_${STRESS_PATTERN}" "CPU0_1P_2L" "run_${WORKLOAD}" "${PARAMETERS[@]}" "${CORES_ARRAY[@]}"

################################################################################################
# CPU1_Single_Core: Stress a single core from CPU1
################################################################################################
TIMESTAMPS_FILE=${LOG_DIR}/CPU1_Single_Core.timestamps
"run_${STRESS_PATTERN}" "CPU1_Single_Core" "run_${WORKLOAD}" "${SINGLE_CORE_PARAMETERS[@]}" "16"

################################################################################################
# CPU1_P&L: Load by pairs of physical and logical cores from CPU1
################################################################################################
TIMESTAMPS_FILE=${LOG_DIR}/CPU1_P_and_L.timestamps
CORES_ARRAY=("16" "48" "17" "49" "18" "50" "19" "51" "20" "52" "21" "53" "22" "54" "23" "55" "24" "56" "25" "57" "26" "58" "27" "59" "28" "60" "29" "61" "30" "62" "31" "63")
"run_${STRESS_PATTERN}" "CPU1_P&L" "run_${WORKLOAD}" "${PARAMETERS[@]}" "${CORES_ARRAY[@]}"

################################################################################################
# CPU1_1P_2L: First CPU1 physical cores, then CPU1 logical cores.
################################################################################################
CORES_ARRAY=("16" "17" "18" "19" "20" "21" "22" "23" "24" "25" "26" "27" "28" "29" "30" "31" "48" "49" "50" "51" "52" "53" "54" "55" "56" "57" "58" "59" "60" "61" "62" "63")
TIMESTAMPS_FILE=${LOG_DIR}/CPU1_1P_2L.timestamps
"run_${STRESS_PATTERN}" "CPU1_1P_2L" "run_${WORKLOAD}" "${PARAMETERS[@]}" "${CORES_ARRAY[@]}"

################################################################################################
END=$(date +%s%N)
NAME="TOTAL"
print_time START END