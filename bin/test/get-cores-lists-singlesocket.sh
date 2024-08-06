#!/bin/bash

# Only one socket, so socket will always be 0
SOCKET=0

export GROUP_P_CORES=()

for ((CORE = 0; CORE < PHY_CORES_PER_CPU; CORE += 1)); do
    KEY="${SOCKET}:${CORE}"
    IFS=',' read -ra LOGICAL_CORES <<< "${CORES_DICT[$KEY]}"
    if [ -n "${LOGICAL_CORES[0]}" ];then
      GROUP_P_CORES+=("${LOGICAL_CORES[0]}")
    fi
done

export GROUP_P_AND_L_CORES=()

for ((CORE = 0; CORE < PHY_CORES_PER_CPU; CORE += 1)); do
    KEY="${SOCKET}:${CORE}"
    IFS=',' read -ra LOGICAL_CORES <<< "${CORES_DICT[$KEY]}"
    for LOGICAL_CORE in 0 1; do
      if [ -n "${LOGICAL_CORES[${LOGICAL_CORE}]}" ];then
        GROUP_P_AND_L_CORES+=("${LOGICAL_CORES[${LOGICAL_CORE}]}")
      fi
    done
done

export GROUP_1P_2L_CORES=()

for LOGICAL_CORE in 0 1; do # First physical cores then logical cores
  for ((CORE = 0; CORE < PHY_CORES_PER_CPU; CORE += 1)); do
      KEY="${SOCKET}:${CORE}"
      IFS=',' read -ra LOGICAL_CORES <<< "${CORES_DICT[$KEY]}"
      if [ -n "${LOGICAL_CORES[${LOGICAL_CORE}]}" ];then
        GROUP_1P_2L_CORES+=("${LOGICAL_CORES[${LOGICAL_CORE}]}")
      fi
  done
done