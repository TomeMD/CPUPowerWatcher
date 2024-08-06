#!/bin/bash

IFS=',' read -ra LOGICAL_CORES <<< "${CORES_DICT[0]}"

# Start tests
START=$(date +%s%N)

################################################################################################
# Single_Core: Stress one core (including physical and logical core)
################################################################################################
TIMESTAMPS_FILE=${LOG_DIR}/Single_Core.timestamps
single_core_experiment "${LOGICAL_CORES[0]}" "${LOGICAL_CORES[1]}"

################################################################################################
END=$(date +%s%N)
NAME="TOTAL"
print_time START END