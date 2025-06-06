#!/usr/bin/env bash

########################################################################################################################
# STAIRS-UP: Stress CPU progressively increasing CPU usage from 0 to maximum supported
########################################################################################################################
function run_stairs-up() {
  # Get arguments
  NAME="${1}"
  local WORKLOAD_FUNCTION="${2}"
  local INITIAL_LOAD="${3}"
  local LOAD_JUMP="${4}"
  shift 4
  local CORES_DISTRIBUTION=("$@")
  local MAX_LOAD=$(( ${#CORES_DISTRIBUTION[@]} * 100 ))
  if [ "${INITIAL_LOAD}" -gt "${MAX_LOAD}" ]; then
    m_warn "Trimming initial load from ${INITIAL_LOAD} to ${MAX_LOAD}"
    INITIAL_LOAD="${MAX_LOAD}"
  fi

  m_echo "Experiment ${NAME}:"
  m_echo "\tStress pattern = ${STRESS_PATTERN}"
  m_echo "\tWorkload function = ${WORKLOAD_FUNCTION}"
  m_echo "\tInitial CPU load = ${INITIAL_LOAD}"
  m_echo "\tLoad jump between iterations = +${LOAD_JUMP} (increase)"

  # Run tests following an ascending staircase pattern
  LOAD=${INITIAL_LOAD}
  local START_TEST=$(date +%s%N)
  while [ "${LOAD}" -le "${MAX_LOAD}" ]; do
    # We need 1 core for 1-100 CPU load, 2 for 101-200, 3 for 201-300...
    NEEDED_CORES=$(( (LOAD + 99) / 100 ))

    # Get first NEEDED_CORES cores from CORES_DISTRIBUTION list
    CURRENT_CORES=$(get_str_list_from_array ${CORES_DISTRIBUTION[@]:0:${NEEDED_CORES}})

    # Run workload
    "${WORKLOAD_FUNCTION}"

    # Increase load for next iteration
    LOAD=$((LOAD + LOAD_JUMP))
  done
  local END_TEST=$(date +%s%N)
  print_time "${START_TEST}" "${END_TEST}"
}

export -f run_stairs-up

########################################################################################################################
# STAIRS-DOWN: Stress CPU progressively decreasing CPU usage from maximum supported to 0
########################################################################################################################
function run_stairs-down() {
  # Get arguments
  NAME="${1}"
  local WORKLOAD_FUNCTION="${2}"
  local INITIAL_LOAD="${3}"
  local LOAD_JUMP="${4}"
  shift 4
  local CORES_DISTRIBUTION=("$@")
  local MAX_LOAD=$(( ${#CORES_DISTRIBUTION[@]} * 100 ))
  if [ "${INITIAL_LOAD}" -gt "${MAX_LOAD}" ]; then
    m_warn "Trimming initial load from ${INITIAL_LOAD} to ${MAX_LOAD}"
    INITIAL_LOAD="${MAX_LOAD}"
  fi

  m_echo "Experiment ${NAME}:"
  m_echo "\tStress pattern = ${STRESS_PATTERN}"
  m_echo "\tWorkload function = ${WORKLOAD_FUNCTION}"
  m_echo "\tInitial CPU load = ${INITIAL_LOAD}"
  m_echo "\tLoad jump between iterations = -${LOAD_JUMP} (decrease)"

  # Run tests following a descending staircase pattern
  LOAD=${INITIAL_LOAD}
  local START_TEST=$(date +%s%N)
  while [ "${LOAD}" -gt "0" ]; do
    # We need 1 core for 1-100 CPU load, 2 for 101-200, 3 for 201-300...
    NEEDED_CORES=$(( (LOAD + 99) / 100 ))

    # Get first NEEDED_CORES cores from CORES_DISTRIBUTION list
    CURRENT_CORES=$(get_str_list_from_array ${CORES_DISTRIBUTION[@]:0:${NEEDED_CORES}})

    # Run workload
    "${WORKLOAD_FUNCTION}"

    # Decrease load for next iteration
    LOAD=$((LOAD - LOAD_JUMP))
  done
  local END_TEST=$(date +%s%N)
  print_time "${START_TEST}" "${END_TEST}"
}

export -f run_stairs-down

########################################################################################################################
# ZIGZAG: Stress CPU jumping from high CPU values to low CPU values, progressively decreasing the magnitude of the jump
########################################################################################################################
function run_zigzag() {
  # Get arguments
  NAME="${1}"
  local WORKLOAD_FUNCTION="${2}"
  local INITIAL_LOAD="${3}"
  local INITIAL_JUMP="${4}"
  local JUMP_DECREASE="${5}"
  local INITIAL_DIRECTION="${6}" # 0 decrease, 1 (or other) increase
  shift 6
  local CORES_DISTRIBUTION=("$@")
  local MAX_LOAD=$(( ${#CORES_DISTRIBUTION[@]} * 100 ))
  if [ "${INITIAL_LOAD}" -gt "${MAX_LOAD}" ]; then
    m_warn "Trimming initial load from ${INITIAL_LOAD} to ${MAX_LOAD}"
    INITIAL_LOAD="${MAX_LOAD}"
  fi
  if [ "${INITIAL_JUMP}" -ge "${MAX_LOAD}" ]; then
    m_warn "Trimming initial jump from ${INITIAL_JUMP} to $((MAX_LOAD - 100))"
    INITIAL_JUMP="$((MAX_LOAD - 100))"
  fi

  m_echo "Experiment ${NAME}:"
  m_echo "\tStress pattern = ${STRESS_PATTERN}"
  m_echo "\tWorkload function = ${WORKLOAD_FUNCTION}"
  m_echo "\tInitial CPU load = ${INITIAL_LOAD}"
  m_echo "\tInitial jump between iterations = ${INITIAL_JUMP} ($([ ${INITIAL_DIRECTION} -eq 0 ] && echo 'decrease' || echo 'increase'))"
  m_echo "\tJump decrease between iterations = -${JUMP_DECREASE}"

  # Run tests following a zigzag pattern
  LOAD=${INITIAL_LOAD}
  local LOAD_JUMP=${INITIAL_JUMP}
  local JUMP_DIRECTION="${INITIAL_DIRECTION}"
  local START_TEST=$(date +%s%N)
  while [ "${LOAD}" -gt "0" ] && [ "${LOAD}" -le "${MAX_LOAD}" ] && [ "${LOAD_JUMP}" -ge "0" ]; do
    # We need 1 core for 1-100 CPU load, 2 for 101-200, 3 for 201-300...
    NEEDED_CORES=$(( (LOAD + 99) / 100 ))

    # Get first NEEDED_CORES cores from CORES_DISTRIBUTION list
    CURRENT_CORES=$(get_str_list_from_array ${CORES_DISTRIBUTION[@]:0:${NEEDED_CORES}})

    # Run workload
    "${WORKLOAD_FUNCTION}"

    # Increase or decrease load for next iteration
    if [ "${JUMP_DIRECTION}" -eq 0 ]; then
      LOAD=$((LOAD - LOAD_JUMP))
      JUMP_DIRECTION=1
    else
      LOAD=$((LOAD + LOAD_JUMP))
      JUMP_DIRECTION=0
    fi
    LOAD_JUMP=$((LOAD_JUMP - JUMP_DECREASE))
  done
  local END_TEST=$(date +%s%N)
  print_time "${START_TEST}" "${END_TEST}"
}

export -f run_zigzag

########################################################################################################################
# UNIFORM: Stress CPU taking CPU usage values from an uniform distribution ranging from 0 to maximum supported
########################################################################################################################
function run_uniform() {
  # Get arguments
  NAME="${1}"
  local WORKLOAD_FUNCTION="${2}"
  local NUM_VALUES="${3}"
  local RANDOM_TIME="${4}"
  shift 4
  local CORES_DISTRIBUTION=("${@}")
  local MAX_LOAD=$(( ${#CORES_DISTRIBUTION[@]} * 100 ))
  local ORIGINAL_TIME="${STRESS_TIME}"

  # Generate uniform distribution between 0 and MAX_LOAD to generate NUM_VALUES values
  #mapfile -t LOAD_VALUES < <("${BIN_DIR}/${WORKLOAD}/generate-uniform.py" "${NUM_VALUES}" "0" "${MAX_LOAD}" "100" "0.5")
  mapfile -t LOAD_VALUES < <("${BIN_DIR}/${WORKLOAD}/generate-uniform.py" "${NUM_VALUES}" "0" "${MAX_LOAD}")
  mapfile -t TIME_VALUES < <("${BIN_DIR}/${WORKLOAD}/generate-uniform.py" "${NUM_VALUES}" "0" "${STRESS_TIME}")

  m_echo "Experiment ${NAME}:"
  m_echo "\tStress pattern = ${STRESS_PATTERN}"
  m_echo "\tWorkload function = ${WORKLOAD_FUNCTION}"
  m_echo "\tNumber of values = ${NUM_VALUES}"

  # Run tests following a uniform pattern
  local START_TEST=$(date +%s%N)
  for i in $(seq 0 $(( NUM_VALUES - 1 ))); do
    LOAD="${LOAD_VALUES[${i}]}"

    # If random time is required take value from uniform distribution ranging from 0 to user-defined stress time (UDRT)
    if [ "${RANDOM_TIME}" -gt "0" ]; then
      STRESS_TIME="${TIME_VALUES[${i}]}"
    fi

    # We need 1 core for 1-100 CPU load, 2 for 101-200, 3 for 201-300...
    NEEDED_CORES=$(( (LOAD + 99) / 100 ))

    # Get first NEEDED_CORES cores from CORES_DISTRIBUTION list
    CURRENT_CORES=$(get_str_list_from_array ${CORES_DISTRIBUTION[@]:0:${NEEDED_CORES}})

    # Run workload
    "${WORKLOAD_FUNCTION}"
  done
  local END_TEST=$(date +%s%N)
  print_time "${START_TEST}" "${END_TEST}"

  # Reset stress time to its original value
  STRESS_TIME="${ORIGINAL_TIME}"
}

export -f run_uniform

########################################################################################################################
# UDRT: Same as uniform but also using random stress times between 0 and user-defined stress time
########################################################################################################################
function run_udrt() {
  # Uniform Distribution with Randomized Times (UDRT)
  run_uniform "${@}"
}

export -f run_udrt