#!/usr/bin/env bash

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
  m_echo "\tStress pattern = stairs-up"
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
  m_echo "\tStress pattern = stairs-down"
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
  m_echo "\tStress pattern = zigzag"
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


function run_uniform() {
  # Get arguments
  NAME="${1}"
  local WORKLOAD_FUNCTION="${2}"
  local NUM_VALUES="${3}"
  shift 3
  local CORES_DISTRIBUTION=("$@")
  local MAX_LOAD=$(( ${#CORES_DISTRIBUTION[@]} * 100 ))

  # Generate uniform distribution between 0 and MAX_LOAD to generate NUM_VALUES values
  mapfile -t LOAD_VALUES < <(python3 -c "import random,sys; num=int(sys.argv[1]); max=int(sys.argv[2]); random.seed(12345); [print(random.randint(0, max)) for _ in range(num)]" "${NUM_VALUES}" "${MAX_LOAD}")

  m_echo "Experiment ${NAME}:"
  m_echo "\tStress pattern = uniform"
  m_echo "\tWorkload function = ${WORKLOAD_FUNCTION}"
  m_echo "\tNumber of values = ${NUM_VALUES}"

  # Run tests following a uniform pattern
  local START_TEST=$(date +%s%N)
  for LOAD in "${LOAD_VALUES[@]}"; do
    # We need 1 core for 1-100 CPU load, 2 for 101-200, 3 for 201-300...
    NEEDED_CORES=$(( (LOAD + 99) / 100 ))

    # Get first NEEDED_CORES cores from CORES_DISTRIBUTION list
    CURRENT_CORES=$(get_str_list_from_array ${CORES_DISTRIBUTION[@]:0:${NEEDED_CORES}})

    # Run workload
    "${WORKLOAD_FUNCTION}"
  done
  local END_TEST=$(date +%s%N)
  print_time "${START_TEST}" "${END_TEST}"
}

export -f run_uniform