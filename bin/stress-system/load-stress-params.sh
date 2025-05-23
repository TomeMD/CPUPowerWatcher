#!/usr/bin/env bash

declare -A PARAMETERS_DICT=(
  [Single_Core]=""
  [Multi_Core]=""
)

########################################################################################################################
# STAIRS-UP: Stress CPU progressively increasing CPU usage from 0 to maximum supported
########################################################################################################################
if [ "${STRESS_PATTERN}" = "stairs-up" ]; then # <INITIAL_LOAD> <LOAD_JUMP>
  # Start at 10 and increase by 10 at each step
  PARAMETERS_DICT[Single_Core]="10,10"
  # Start at 100 (one core) and increase by 100 at each step
  PARAMETERS_DICT[Multi_Core]="100,100"

########################################################################################################################
# STAIRS-DOWN: Stress CPU progressively decreasing CPU usage from maximum supported to 0
########################################################################################################################
elif [ "${STRESS_PATTERN}" = "stairs-down" ]; then # <INITIAL_LOAD> <LOAD_JUMP>
  # Start at 100 (one core) and decrease by 10 at each step
  PARAMETERS_DICT[Single_Core]="100,10"
  # Start at maximum and decrease by 100 (one core) at each step
  PARAMETERS_DICT[Multi_Core]="${MAX_SUPPORTED_LOAD},100"

########################################################################################################################
# ZIGZAG: Stress CPU jumping from high CPU values to low CPU values, progressively decreasing the magnitude of the jump
########################################################################################################################
elif [ "${STRESS_PATTERN}" = "zigzag" ]; then # <INITIAL_LOAD> <INITIAL_JUMP> <JUMP_DECREASE> <INITIAL_DIRECTION>
  # Start at 100, decrease 90 to 10, increase 80 to 90, decrease 70 to 20...
  PARAMETERS_DICT[Single_Core]="100,90,10,0"
  # Start at maximum, decrease 'maximum - 100' to 100, increase 'maximum - 200' to 'maximum - 100'...
  PARAMETERS_DICT[Multi_Core]="${MAX_SUPPORTED_LOAD},$((MAX_SUPPORTED_LOAD - 100)),100,0"

########################################################################################################################
# UNIFORM: Stress CPU taking CPU usage values from an uniform distribution ranging from 0 to maximum supported
########################################################################################################################
elif [ "${STRESS_PATTERN}" = "uniform" ]; then # <NUM_VALUES> <RANDOM_TIME>
  # Follow an uniform distribution between 0 and 100 (one core) composed of 100 values
  PARAMETERS_DICT[Single_Core]="100,0"
  # Follow an uniform distribution between 0 and maximum composed of 500 values
  PARAMETERS_DICT[Multi_Core]="500,0"

########################################################################################################################
# UDRT: Same as uniform but also using random stress times between 0 and user-defined stress time
########################################################################################################################
elif [ "${STRESS_PATTERN}" = "udrt" ]; then # <NUM_VALUES> <RANDOM_TIME>
  # Follow an uniform distribution between 0 and 100 (one core) composed of 100 values and randomized times
  PARAMETERS_DICT[Single_Core]="100,1"
  # Follow an uniform distribution between 0 and maximum composed of 500 values and randomized times
  PARAMETERS_DICT[Multi_Core]="6000,1"
fi