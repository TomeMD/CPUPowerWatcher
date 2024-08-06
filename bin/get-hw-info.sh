#!/bin/bash

export PHY_CORES_PER_CPU=$(lscpu | grep "Core(s) per socket:" | awk '{print $4}')
export SOCKETS=$(lscpu | grep "Socket(s):" | awk '{print $2}')
export THREADS=$((PHY_CORES_PER_CPU * SOCKETS * 2))

# FIRST_CORE_SOCKET stores the number assigned to the first physical core of each socket
declare -A FIRST_CORE_SOCKET

# CORES_DICT stores each physical core as key and its logical cores as value
declare -A CORES_DICT

output=$(lscpu -e | awk 'NR > 1 { print $1, $3, $4 }')
while read -r CPU SOCKET CORE; do
    # First core will be the lowest number found for each socket
    if [ -z "${FIRST_CORE_SOCKET[${SOCKET}]}" ]; then
        FIRST_CORE_SOCKET["${SOCKET}"]="${CORE}"
    elif [ "${CORE}" -lt "${FIRST_CORE_SOCKET[${SOCKET}]}" ]; then
        FIRST_CORE_SOCKET[${SOCKET}]="${CORE}"
    fi

    # We use KEY to index by socket and cores, as bash doesn't support nested dictionaries
    KEY="$SOCKET:$CORE"
    if [ -z "${CORES_DICT[${KEY}]}" ]; then
        CORES_DICT["${KEY}"]="$CPU"
    else
        CORES_DICT["${KEY}"]="${CORES_DICT[${KEY}]},$CPU"
    fi
done <<< "$output"

