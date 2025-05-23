#!/usr/bin/env bash

declare -A CORES_ARRAYS_DICT=(
  [Single_Core]=""
  [Group_P]=""
  [Group_P_and_L]=""
  [Group_1P_2L]=""
)

SOCKET=0 # Only one socket, so socket will always be 0

################################################################################################
# Single_Core: Stress a single core
################################################################################################
CORES_ARRAYS_DICT[Single_Core]+=("0")

################################################################################################
# Group_P: Only physical cores.
################################################################################################
for ((CORE = 0; CORE < PHY_CORES_PER_CPU; CORE += 1)); do
    KEY="${SOCKET}:${CORE}"
    IFS=',' read -ra LOGICAL_CORES <<< "${CORES_DICT[$KEY]}"
    if [ -n "${LOGICAL_CORES[0]}" ];then
      CORES_ARRAYS_DICT[Group_P]+="${LOGICAL_CORES[0]},"
    fi
done
CORES_ARRAYS_DICT[Group_P]=${CORES_ARRAYS_DICT[Group_P]:0:-1}

################################################################################################
# Group_P&L: Pairs of physical and logical cores.
################################################################################################
for ((CORE = 0; CORE < PHY_CORES_PER_CPU; CORE += 1)); do
    KEY="${SOCKET}:${CORE}"
    IFS=',' read -ra LOGICAL_CORES <<< "${CORES_DICT[$KEY]}"
    for LOGICAL_CORE in 0 1; do
      if [ -n "${LOGICAL_CORES[${LOGICAL_CORE}]}" ];then
        CORES_ARRAYS_DICT[Group_P_and_L]+="${LOGICAL_CORES[${LOGICAL_CORE}]},"
      fi
    done
done
CORES_ARRAYS_DICT[Group_P_and_L]=${CORES_ARRAYS_DICT[Group_P_and_L]:0:-1}

################################################################################################
# Group_1P_2L: Physical cores first, then logical cores.
################################################################################################
for LOGICAL_CORE in 0 1; do # First physical cores then logical cores
  for ((CORE = 0; CORE < PHY_CORES_PER_CPU; CORE += 1)); do
      KEY="${SOCKET}:${CORE}"
      IFS=',' read -ra LOGICAL_CORES <<< "${CORES_DICT[$KEY]}"
      if [ -n "${LOGICAL_CORES[${LOGICAL_CORE}]}" ];then
        CORES_ARRAYS_DICT[Group_1P_2L]+="${LOGICAL_CORES[${LOGICAL_CORE}]},"
      fi
  done
done
CORES_ARRAYS_DICT[Group_1P_2L]=${CORES_ARRAYS_DICT[Group_1P_2L]:0:-1}