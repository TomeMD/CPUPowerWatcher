#!/bin/bash

output=$(lscpu -e | awk 'NR > 1 { print $1, $4 }')
declare -A CORES_DICT
while read -r cpu core; do
    if [ -z "${CORES_DICT[$core]}" ]; then
        CORES_DICT["$core"]="$cpu"
    else
        CORES_DICT["$core"]="${CORES_DICT[$core]},$cpu"
    fi
done <<< "$output"

export SEQUENTIAL_CORES=()

for ((CORE = 0; CORE < ${#CORES_DICT[@]}; CORE += 1)); do
    IFS=',' read -ra LOGICAL_CORES <<< "${CORES_DICT[$CORE]}"
    SEQUENTIAL_CORES+=("${LOGICAL_CORES[0]}")
    if [ -n "${LOGICAL_CORES[1]}" ];then
      SEQUENTIAL_CORES+=("${LOGICAL_CORES[1]}")
    fi
done

