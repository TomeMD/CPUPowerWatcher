#!/usr/bin/env bash

if [ "${STRESS_PATTERN}" = "stairs-up" ]; then # <INITIAL_LOAD> <LOAD_JUMP>
  # Start at 10 and increase by 10 at each step
  export SINGLE_CORE_PARAMETERS=("10" "10")
  # Start at 100 (one core) and increase by 100 at each step
  export PARAMETERS=("100" "100")

elif [ "${STRESS_PATTERN}" = "stairs-down" ]; then # <INITIAL_LOAD> <LOAD_JUMP>
  # Start at 100 (one core) and decrease by 10 at each step
  export SINGLE_CORE_PARAMETERS=("100" "10")
  # Start at maximum and decrease by 100 (one core) at each step
  export PARAMETERS=("${MAX_SUPPORTED_LOAD}" "100")

elif [ "${STRESS_PATTERN}" = "zigzag" ]; then # <INITIAL_LOAD> <INITIAL_JUMP> <JUMP_DECREASE> <INITIAL_DIRECTION>
  # Start at 100, decrease 90 to 10, increase 80 to 90, decrease 70 to 20...
  export SINGLE_CORE_PARAMETERS=("100" "90" "10" "0")
  # Start at maximum, decrease 'maximum - 100' to 100, increase 'maximum - 200' to 'maximum - 100'...
  export PARAMETERS=("${MAX_SUPPORTED_LOAD}" "$((MAX_SUPPORTED_LOAD - 100))" "100" "0")

elif [ "${STRESS_PATTERN}" = "uniform" ]; then # <NUM_VALUES>
  # Follow an uniform distribution between 0 and 100 (one core) composed of 100 values
  export SINGLE_CORE_PARAMETERS=("100")
  # Follow an uniform distribution between 0 and maximum composed of 500 values
  export PARAMETERS=("500")
fi