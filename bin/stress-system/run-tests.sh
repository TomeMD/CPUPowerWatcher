#!/usr/bin/env bash

# Load parameters for the specified stress pattern
. "${BIN_DIR}/${WORKLOAD}/load-stress-params.sh"

# Load pattern functions
. "${BIN_DIR}/${WORKLOAD}/load-stress-patterns.sh"

# Load core distributions for current CPU topology
. "${BIN_DIR}/${WORKLOAD}/load-${CPU_TOPOLOGY}-distributions.sh"

# Initial wait
sleep 30

# Start tests
START=$(date +%s%N)
for CORE_DIST in "${FINAL_CORE_DISTRIBUTIONS[@]}"; do
  # Set a separated timestamp file for each core distribution
  TIMESTAMPS_FILE=${LOG_DIR}/"${CORE_DIST}".timestamps

  # Get cores from current core distribution
  IFS=',' read -r -a DIST_CORES_ARRAY <<< "${CORES_ARRAYS_DICT[${CORE_DIST}]}"

  # Single core distribution use different parameters
  if [ "${CORE_DIST}" == "Single_Core" ]; then
    IFS=',' read -r -a PARAMS <<< "${PARAMETERS_DICT[Single_Core]}"
  else
    IFS=',' read -r -a PARAMS <<< "${PARAMETERS_DICT[Multi_Core]}"
  fi

  # Run workload following stress pattern using current core distribution
  "run_${STRESS_PATTERN}" "${CORE_DIST}" "run_${WORKLOAD}" "${PARAMS[@]}" "${DIST_CORES_ARRAY[@]}"
done
END=$(date +%s%N)

# Save total experiments time
NAME="TOTAL"
print_time START END