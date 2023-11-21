#!/bin/bash

export SEQUENTIAL_CORES=()

for ((CORE = 0; CORE < ${#CORES_DICT[@]}; CORE += 1)); do
    IFS=',' read -ra LOGICAL_CORES <<< "${CORES_DICT[$CORE]}"
    SEQUENTIAL_CORES+=("${LOGICAL_CORES[0]}")
    if [ -n "${LOGICAL_CORES[1]}" ];then
      SEQUENTIAL_CORES+=("${LOGICAL_CORES[1]}")
    fi
done

