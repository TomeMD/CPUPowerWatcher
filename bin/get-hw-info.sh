#!/bin/bash

export PHY_CORES_PER_CPU=$(lscpu | grep "Core(s) per socket:" | awk '{print $4}')
export SOCKETS=$(lscpu | grep "Socket(s):" | awk '{print $2}')
export THREADS=$(nproc)
export THEORETICAL_THREADS=$((PHY_CORES_PER_CPU * SOCKETS * 2))
export MAX_SUPPORTED_LOAD=$(( THREADS * 100 ))

export MULTITHREADING_SUPPORT="FULLY SUPPORTED"
if [ "${THREADS}" -lt "${THEORETICAL_THREADS}" ]; then
  if [ "${THREADS}" -gt "$(( THEORETICAL_THREADS / 2 ))" ]; then
      MULTITHREADING_SUPPORT="SUPPORTED IN SOME CORES"
  else
      MULTITHREADING_SUPPORT="NOT SUPPORTED"
  fi
fi

# FIRST_CORE_SOCKET stores the number assigned to the first physical core of each socket
declare -A FIRST_CORE_SOCKET

# CORES_DICT stores each physical core as key and its logical cores as value
declare -A CORES_DICT

export CORES_WITH_MULTITHREADING=()
OUTPUT=$(lscpu -e | awk 'NR > 1 { print $1, $3, $4 }')
while read -r CPU SOCKET CORE; do
    # First core will be the lowest number found for each socket
    if [ -z "${FIRST_CORE_SOCKET[${SOCKET}]}" ]; then
        FIRST_CORE_SOCKET["${SOCKET}"]="${CORE}"
    elif [ "${CORE}" -lt "${FIRST_CORE_SOCKET[${SOCKET}]}" ]; then
        FIRST_CORE_SOCKET[${SOCKET}]="${CORE}"
    fi

    # We use KEY to index by socket and cores, as bash does not support nested dictionaries
    KEY="$SOCKET:$CORE"
    if [ -z "${CORES_DICT[${KEY}]}" ]; then
        CORES_DICT["${KEY}"]="$CPU"
    else
        CORES_DICT["${KEY}"]="${CORES_DICT[${KEY}]},$CPU"
        CORES_WITH_MULTITHREADING+=("${CORE}")
        # PHYSICAL CORES WITH MULTITHREDING += 1
    fi
done <<< "${OUTPUT}"

