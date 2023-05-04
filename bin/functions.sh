#!/bin/sh


function print_time() {
	echo "$NAME CPU TIME: $(bc <<< "scale=9; $(($2 - $1)) / 1000000000")" | tee -a $LOG_FILE
}

export -f print_time

function print_timestamp() {
	local DESCRIPTION=$1
	echo "$NAME $DESCRIPTION: $(date -u "+%Y-%m-%d %H:%M:%S%z")" | tee -a $TIMESTAMPS_FILE
}

export -f print_timestamp

function get_cores() {
	CORE_0=${CORES_ARRAY[$((CPU % 2))]}
	CORE_1=$((CORE_0 + PAIR_OFFSET))
	if [ -z "$CORES" ]; then
	  CORES+="$CORE_0,$CORE_1"
	else
	  CORES+=",$CORE_0,$CORE_1"
	fi
	CORES_ARRAY[$((CPU % 2))]=$(($CORE_0 + $INCREMENT))
}

export -f get_cores

function stress_cpu() {
	print_timestamp "STRESS-TEST (CORES = $CORES) START"
	if [ "$USE_DOCKER" -eq "0" ]; then
		docker run --name stress-system -it stress-system -l $LOAD -c $CORES -t 2m >> $LOG_FILE 2>&1
		docker rm stress-system > /dev/null
	else
		apptainer run ${STRESS_HOME}/stress.sif -l $LOAD -c $CORES -t 2m >> $LOG_FILE 2>&1
	fi
	print_timestamp "STRESS-TEST (CORES = $CORES) STOP"
	sleep 15
}

export -f stress_cpu

function idle_cpu() {
	print_timestamp "IDLE START"
	sleep 30
	print_timestamp "IDLE STOP"
	sleep 5
}

export -f idle_cpu

################################################################################################
# run_experiment <NAME> <CORES_PER_CPU> <PAIR_OFFSET> <INCREMENT> <CPU_SWITCH> <TOTAL_PAIRS>
################################################################################################
# <NAME>: Name of the experiment
#
# <CORES_PER_CPU>: Physical cores per CPU 
#
# <TOTAL_PAIRS>: Total number of pairs of cores.
#
# <PAIR_OFFSET>: Distance between the cores in a pair, for example, if we use pairs 
# (0,16), (1,17),... PAIR_OFFSET will be 16.
#
# <INCREMENT>: Increment of the number of the first core of each pair between iterations. This 
# INCREMENT is applied independently to the pairs of each CPU. Examples:
#     cores=(0 1 2 3 4 5 6 7) INCREMENT=2
#     cores=(0 16 8 24 1 17 9 25) INCREMENT=1
#
# <CPU_SWITCH>: Frequency in iterations to switch between CPUs. Set 0 to avoid switching 
# between CPUs.
#

################################################################################################
function run_experiment() { 
	NAME=$1
	CORES_PER_CPU=$2
	TOTAL_PAIRS=$3
	PAIR_OFFSET=$4
	INCREMENT=$5
	CPU_SWITCH=$6
	if [ $CPU_SWITCH -eq $(($CORES_PER_CPU / 2)) ]; then
		CORES_ARRAY=(0 $(($CORES_PER_CPU * 2)))
	else
		CORES_ARRAY=(0 $CORES_PER_CPU)
	fi
	CPU=0
	CORES=""
	LOAD=200
	local PAIRS_COUNT=0
	local START_TEST=$(date +%s%N)
	while [ $PAIRS_COUNT -lt $TOTAL_PAIRS ]; do
	    get_cores
	    stress_cpu
	    idle_cpu
	    LOAD=$((LOAD + 200))
	    PAIRS_COUNT=$((PAIRS_COUNT + 1))
		if [ $CPU_SWITCH -ne 0 ] && [ $((PAIRS_COUNT % CPU_SWITCH)) -eq 0 ]; then
			CPU=$((CPU + 1))
		fi  
	done
	local END_TEST=$(date +%s%N)
  	print_time $START_TEST $END_TEST
}

export -f run_experiment