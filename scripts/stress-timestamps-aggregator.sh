#!/usr/bin/env bash
################################################################################################
# INSTRUCTIONS
################################################################################################
# This script aggregates several timestamp files in a single one. Follow this steps:
#   1. Get all the timestamp files you want running CPUPowerWatcher using 'stress-system' workload and different stress
#      load types (--stress-load-types option). Remember to store all the results in a common directory (e.g., -o
#      <common_dir>/<stress_load_type>).
#   2. Custom the configuration of this file with the stress load types you have run. Note that you should indicate the
#      names of the directories containing the timestamps of each stress load type (i.e., the names you indicated as
#      <stress_load_type> in the previous step). Indicate the topology of your CPU, "singlesocket" or "multisocket".
#   3. Run the timestamps aggregator indicating the base directory (i.e., previous <common_dir>) and name of the file
#      you want to aggregate all the timestamps.
#   4. A directory called 'out' will be created inside <common_dir> containing:
#       - A file with the specified name with all the timestamps inside.
#       - A file for each stress load type containing all the timestamps corresponding to it.
#       - A file for each core distribution containing all the timestamps corresponding to it.
#

################################################################################################
# ADDITIONAL CONFIGURATION PARAMETERS
################################################################################################
STRESS_LOAD_TYPES=("all" "sysinfo" "sysinfo_all")
CPU_TOPOLOGY="multisocket"  # "singlesocket" or "multisocket"
declare -A SOCKET_CORE_DISTRIBUTIONS=(
  [singlesocket]="Single_Core,Group_P,Group_P_and_L,Group_1P_2L"
  [multisocket]="Single_Core,Group_P,Spread_P,Group_P_and_L,Group_1P_2L,Group_PP_LL,Spread_P_and_L,Spread_PP_LL"
)
# Single-socket distributions:  "Single_Core,Group_P,Spread_P,Group_P_and_L,Group_1P_2L,Group_PP_LL,Spread_P_and_L,Spread_PP_LL"
# Multi-socket distributions:   "Group_PP_LL,Group_P,Group_P_and_L,Single_Core,Group_1P_2L,Spread_P_and_L,Spread_P,Spread_PP_LL"
################################################################################################

if [ -z "${2}" ]; then
  echo "At least one argument is needed"
  echo "1 -> Absolute path for the base directory containing logs for different stress load types"
  echo "2 -> Name of the file containing all the timestamps (e.g., General)"
  exit 1
fi

BASE_DIR=$(readlink -f -- "${1}")
RESULTS_NAME="${2}"
OUTPUT_DIR="${BASE_DIR}/out"

if [[ ! -d "$BASE_DIR" ]]; then
  echo "Error: Base directory does not exist: $BASE_DIR" >&2
  exit 1
fi

# Prepare output
rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"

# Define core distributions by topology
IFS=',' read -r -a CORES_DISTRIBUTIONS <<< "${SOCKET_CORE_DISTRIBUTIONS[$CPU_TOPOLOGY]}"

# Collect idle timestamp files
collect_idle() {
  local IDLE_FILES
  mapfile -t IDLE_FILES < <(find "${BASE_DIR}" -type f -name "idle.timestamps")
  if [[ ${#IDLE_FILES[@]} -eq 0 ]]; then
    echo "Error: No idle.timestamps files found." >&2
    echo "Run CPUPowerWatcher with --base at least once within all the experiments." >&2
    exit 1
  fi

  for FILE in "${IDLE_FILES[@]}"; do
    cat "${FILE}" >> "${OUTPUT_DIR}/idle.timestamps"
  done

  # Count lines to skip later
  IDLE_LINE_COUNT=$(( $(wc -l < "${OUTPUT_DIR}/idle.timestamps") ))
}

# Initialize file with idle timestamps if it does not exist
append_with_idle() {
  local TARGET_FILE="${1}"
  local TARGET_FILE_NAME="${2}"
  if [[ ! -f "${TARGET_FILE}" ]]; then
    cat "${OUTPUT_DIR}/idle.timestamps" > "${TARGET_FILE}"
    echo "  * Initialise (OUT) idle.timestamps → (OUT) ${TARGET_FILE_NAME}"
  fi
}

# Process a single stress load type
process_load() {
  local LOAD="${1}"
  local INPUT_DIR="${BASE_DIR}/${LOAD}"
  echo "=============================================================================="
  echo " Processing stress load: LOAD"
  echo "  INPUT:  ${INPUT_DIR}"
  echo "  OUTPUT: ${OUTPUT_DIR}"
  echo "=============================================================================="

  for CORE_DIST in "${CORES_DISTRIBUTIONS[@]}"; do
    local INPUT_FILE="${INPUT_DIR}/${CORE_DIST}.timestamps"
    local OUT_CORE="${OUTPUT_DIR}/${CORE_DIST}.timestamps"
    local OUT_LOAD="${OUTPUT_DIR}/${LOAD}.timestamps"

    # Append timestamps to core distribution file
    append_with_idle "${OUT_CORE}" "${CORE_DIST}.timestamps"
    cat "${INPUT_FILE}" >> "${OUT_CORE}"
    echo "  + Appended (IN) ${CORE_DIST}.timestamps → (OUT) ${CORE_DIST}.timestamps"

    # Append timestamps to workload file
    append_with_idle "${OUT_LOAD}" "${LOAD}.timestamps"
    cat "${INPUT_FILE}" >> "${OUT_LOAD}"
    echo "  + Appended (IN) ${CORE_DIST}.timestamps → (OUT) ${LOAD}.timestamps"
  done

  # Append workload timestamps to general file, skipping idle lines
  awk "NR > ${IDLE_LINE_COUNT}" "${OUTPUT_DIR}/${LOAD}.timestamps" >> "${OUTPUT_DIR}/${RESULTS_NAME}.timestamps"
  echo "  + Appended (OUT) ${LOAD}.timestamps (skipped ${IDLE_LINE_COUNT} lines) → (OUT) ${RESULTS_NAME}.timestamps"
  echo
}


################################################################################################
# PROCESS TIMESTAMP FILES
################################################################################################

# Collect all files containing timestamps corresponding to idle periods
collect_idle

# Seed general results file with idle timestamps
cat "${OUTPUT_DIR}/idle.timestamps" > "${OUTPUT_DIR}/${RESULTS_NAME}.timestamps"

for LOAD in "${STRESS_LOAD_TYPES[@]}"; do
  process_load "${LOAD}"
done

echo "All results have been stored under: ${OUTPUT_DIR}"

