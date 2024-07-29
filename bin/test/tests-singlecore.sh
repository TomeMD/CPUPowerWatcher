#!/bin/bash


IFS=',' read -ra LOGICAL_CORES <<< "${CORES_DICT[0]}"

################################################################################################
# Single_Core: Stress one core (including physical and logical core)
################################################################################################
TIMESTAMPS_FILE=${LOG_DIR}/SingleCore.timestamps
single_core_experiment "${LOGICAL_CORES[0]}" "${LOGICAL_CORES[1]}"