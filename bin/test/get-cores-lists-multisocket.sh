#!/bin/bash

export GROUP_P_CORES=()

for SOCKET in 0 1; do
  for (( CORE = ${FIRST_CORE_SOCKET[$SOCKET]}; CORE < $(( ${FIRST_CORE_SOCKET[$SOCKET]} + PHY_CORES_PER_CPU )); CORE += 1)); do
      KEY="${SOCKET}:${CORE}"
      IFS=',' read -ra LOGICAL_CORES <<< "${CORES_DICT[${KEY}]}"
      if [ -n "${LOGICAL_CORES[0]}" ];then
        GROUP_P_CORES+=("${LOGICAL_CORES[0]}")
      fi
  done
done

export SPREAD_P_CORES=()

for (( CORE = 0; CORE < PHY_CORES_PER_CPU; CORE += 2)); do
  for SOCKET in 0 1; do
    CORE_SOCKET_1=$(( ${FIRST_CORE_SOCKET[$SOCKET]} + CORE ))
    CORE_SOCKET_2=$(( CORE_SOCKET_1 + 1 ))
    KEY_1="${SOCKET}:${CORE_SOCKET_1}"
    KEY_2="${SOCKET}:${CORE_SOCKET_2}"
    for KEY in "${KEY_1}" "${KEY_2}"; do
      IFS=',' read -ra LOGICAL_CORES <<< "${CORES_DICT[${KEY}]}"
      if [ -n "${LOGICAL_CORES[0]}" ];then
        SPREAD_P_CORES+=("${LOGICAL_CORES[0]}")
      fi
    done
  done
done

export GROUP_P_AND_L_CORES=()

for SOCKET in 0 1; do
  for (( CORE = ${FIRST_CORE_SOCKET[$SOCKET]}; CORE < $(( ${FIRST_CORE_SOCKET[$SOCKET]} + PHY_CORES_PER_CPU )); CORE += 1)); do
      KEY="${SOCKET}:${CORE}"
      IFS=',' read -ra LOGICAL_CORES <<< "${CORES_DICT[${KEY}]}"
      for LOGICAL_CORE in 0 1;do
        if [ -n "${LOGICAL_CORES[${LOGICAL_CORE}]}" ];then
          GROUP_P_AND_L_CORES+=("${LOGICAL_CORES[${LOGICAL_CORE}]}")
        fi
      done
  done
done

export GROUP_1P_2L_CORES=()

for SOCKET in 0 1; do
  for LOGICAL_CORE in 0 1;do
    for (( CORE = ${FIRST_CORE_SOCKET[$SOCKET]}; CORE < $(( ${FIRST_CORE_SOCKET[$SOCKET]} + PHY_CORES_PER_CPU )); CORE += 1)); do
        KEY="${SOCKET}:${CORE}"
        IFS=',' read -ra LOGICAL_CORES <<< "${CORES_DICT[${KEY}]}"
        if [ -n "${LOGICAL_CORES[${LOGICAL_CORE}]}" ];then
          GROUP_1P_2L_CORES+=("${LOGICAL_CORES[${LOGICAL_CORE}]}")
        fi
    done
  done
done

export GROUP_PP_LL_CORES=()

for LOGICAL_CORE in 0 1;do
  for SOCKET in 0 1; do
    for (( CORE = ${FIRST_CORE_SOCKET[$SOCKET]}; CORE < $(( ${FIRST_CORE_SOCKET[$SOCKET]} + PHY_CORES_PER_CPU )); CORE += 1)); do
        KEY="${SOCKET}:${CORE}"
        IFS=',' read -ra LOGICAL_CORES <<< "${CORES_DICT[${KEY}]}"
        if [ -n "${LOGICAL_CORES[${LOGICAL_CORE}]}" ];then
          GROUP_PP_LL_CORES+=("${LOGICAL_CORES[${LOGICAL_CORE}]}")
        fi
    done
  done
done

export SPREAD_P_AND_L_CORES=()

for (( CORE = 0; CORE < PHY_CORES_PER_CPU; CORE += 1)); do
  for SOCKET in 0 1; do
    CORE_SOCKET=$(( ${FIRST_CORE_SOCKET[$SOCKET]} + CORE ))
    KEY="${SOCKET}:${CORE_SOCKET}"
    IFS=',' read -ra LOGICAL_CORES <<< "${CORES_DICT[${KEY}]}"
    for LOGICAL_CORE in 0 1; do
      if [ -n "${LOGICAL_CORES[${LOGICAL_CORE}]}" ];then
        SPREAD_P_AND_L_CORES+=("${LOGICAL_CORES[${LOGICAL_CORE}]}")
      fi
    done
  done
done

export SPREAD_PP_LL_CORES=()

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
          SPREAD_PP_LL_CORES+=("${LOGICAL_CORES[${LOGICAL_CORE}]}")
        fi
      done
    done
  done
done
