#!/usr/bin/env bash

declare -A CORES_ARRAYS_DICT=(
  [Single_Core]=""
  [Group_P]=""
  [Spread_P]=""
  [Group_P_and_L]=""
  [Group_1P_2L]=""
  [Group_PP_LL]=""
  [Spread_P_and_L]=""
  [Spread_PP_LL]=""
)

################################################################################################
# Single_Core: Stress a single core
################################################################################################
CORES_ARRAYS_DICT[Single_Core]="0"

################################################################################################
# Group_P: Only physical cores, one CPU at a time.
################################################################################################
for SOCKET in 0 1; do
  for (( CORE = ${FIRST_CORE_SOCKET[$SOCKET]}; CORE < $(( ${FIRST_CORE_SOCKET[$SOCKET]} + PHY_CORES_PER_CPU )); CORE += 1)); do
      KEY="${SOCKET}:${CORE}"
      IFS=',' read -ra LOGICAL_CORES <<< "${CORES_DICT[${KEY}]}"
      if [ -n "${LOGICAL_CORES[0]}" ];then
        CORES_ARRAYS_DICT[Group_P]+="${LOGICAL_CORES[0]},"
      fi
  done
done
CORES_ARRAYS_DICT[Group_P]=${CORES_ARRAYS_DICT[Group_P]:0:-1}

################################################################################################
# Spread_P: Only physical cores, alternating between CPUs.
################################################################################################
for (( CORE = 0; CORE < PHY_CORES_PER_CPU; CORE += 2)); do
  for SOCKET in 0 1; do
    CORE_SOCKET_1=$(( ${FIRST_CORE_SOCKET[$SOCKET]} + CORE ))
    CORE_SOCKET_2=$(( CORE_SOCKET_1 + 1 ))
    KEY_1="${SOCKET}:${CORE_SOCKET_1}"
    KEY_2="${SOCKET}:${CORE_SOCKET_2}"
    for KEY in "${KEY_1}" "${KEY_2}"; do
      IFS=',' read -ra LOGICAL_CORES <<< "${CORES_DICT[${KEY}]}"
      if [ -n "${LOGICAL_CORES[0]}" ];then
        CORES_ARRAYS_DICT[Spread_P]+="${LOGICAL_CORES[0]},"
      fi
    done
  done
done
CORES_ARRAYS_DICT[Spread_P]=${CORES_ARRAYS_DICT[Spread_P]:0:-1}

################################################################################################
# Group_P&L: Pairs of physical and logical cores, one CPU at a time.
################################################################################################
for SOCKET in 0 1; do
  for (( CORE = ${FIRST_CORE_SOCKET[$SOCKET]}; CORE < $(( ${FIRST_CORE_SOCKET[$SOCKET]} + PHY_CORES_PER_CPU )); CORE += 1)); do
      KEY="${SOCKET}:${CORE}"
      IFS=',' read -ra LOGICAL_CORES <<< "${CORES_DICT[${KEY}]}"
      for LOGICAL_CORE in 0 1;do
        if [ -n "${LOGICAL_CORES[${LOGICAL_CORE}]}" ];then
          CORES_ARRAYS_DICT[Group_P_and_L]+="${LOGICAL_CORES[${LOGICAL_CORE}]},"
        fi
      done
  done
done
CORES_ARRAYS_DICT[Group_P_and_L]=${CORES_ARRAYS_DICT[Group_P_and_L]:0:-1}

################################################################################################
# Group_1P_2L: Physical cores first, then logical cores, one CPU at a time.
################################################################################################
for SOCKET in 0 1; do
  for LOGICAL_CORE in 0 1;do
    for (( CORE = ${FIRST_CORE_SOCKET[$SOCKET]}; CORE < $(( ${FIRST_CORE_SOCKET[$SOCKET]} + PHY_CORES_PER_CPU )); CORE += 1)); do
        KEY="${SOCKET}:${CORE}"
        IFS=',' read -ra LOGICAL_CORES <<< "${CORES_DICT[${KEY}]}"
        if [ -n "${LOGICAL_CORES[${LOGICAL_CORE}]}" ];then
          CORES_ARRAYS_DICT[Group_1P_2L]+="${LOGICAL_CORES[${LOGICAL_CORE}]},"
        fi
    done
  done
done
CORES_ARRAYS_DICT[Group_1P_2L]=${CORES_ARRAYS_DICT[Group_1P_2L]:0:-1}

################################################################################################
# Group_PP_LL: Physical cores first, one CPU at a time, then logical cores.
################################################################################################
for LOGICAL_CORE in 0 1;do
  for SOCKET in 0 1; do
    for (( CORE = ${FIRST_CORE_SOCKET[$SOCKET]}; CORE < $(( ${FIRST_CORE_SOCKET[$SOCKET]} + PHY_CORES_PER_CPU )); CORE += 1)); do
        KEY="${SOCKET}:${CORE}"
        IFS=',' read -ra LOGICAL_CORES <<< "${CORES_DICT[${KEY}]}"
        if [ -n "${LOGICAL_CORES[${LOGICAL_CORE}]}" ];then
          CORES_ARRAYS_DICT[Group_PP_LL]+="${LOGICAL_CORES[${LOGICAL_CORE}]},"
        fi
    done
  done
done
CORES_ARRAYS_DICT[Group_PP_LL]=${CORES_ARRAYS_DICT[Group_PP_LL]:0:-1}

################################################################################################
# Spread_P&L: Pairs of physical and logical cores, alternating between CPUs.
################################################################################################
for (( CORE = 0; CORE < PHY_CORES_PER_CPU; CORE += 1)); do
  for SOCKET in 0 1; do
    CORE_SOCKET=$(( ${FIRST_CORE_SOCKET[$SOCKET]} + CORE ))
    KEY="${SOCKET}:${CORE_SOCKET}"
    IFS=',' read -ra LOGICAL_CORES <<< "${CORES_DICT[${KEY}]}"
    for LOGICAL_CORE in 0 1; do
      if [ -n "${LOGICAL_CORES[${LOGICAL_CORE}]}" ];then
        CORES_ARRAYS_DICT[Spread_P_and_L]+="${LOGICAL_CORES[${LOGICAL_CORE}]},"
      fi
    done
  done
done
CORES_ARRAYS_DICT[Spread_P_and_L]=${CORES_ARRAYS_DICT[Spread_P_and_L]:0:-1}

################################################################################################
# Spread_PP_LL: Physical cores first, alternating between CPUs, then logical cores.
################################################################################################
for LOGICAL_CORE in 0 1; do
  for (( CORE = 0; CORE < PHY_CORES_PER_CPU; CORE += 2)); do
    for SOCKET in 0 1; do
      CORE_SOCKET_1=$(( ${FIRST_CORE_SOCKET[$SOCKET]} + CORE ))
      CORE_SOCKET_2=$(( CORE_SOCKET_1 + 1 ))
      KEY_1="${SOCKET}:${CORE_SOCKET_1}"
      KEY_2="${SOCKET}:${CORE_SOCKET_2}"
      for KEY in "${KEY_1}" "${KEY_2}"; do
        IFS=',' read -ra LOGICAL_CORES <<< "${CORES_DICT[${KEY}]}"
        if [ -n "${LOGICAL_CORES[${LOGICAL_CORE}]}" ];then
          CORES_ARRAYS_DICT[Spread_PP_LL]+="${LOGICAL_CORES[${LOGICAL_CORE}]},"
        fi
      done
    done
  done
done
CORES_ARRAYS_DICT[Spread_PP_LL]=${CORES_ARRAYS_DICT[Spread_PP_LL]:0:-1}
