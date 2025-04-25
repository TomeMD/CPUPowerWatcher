#!/bin/bash

STR_LIST=$(get_comma_separated_list 0 "${THREADS}")
IFS=',' read -ra SEQUENTIAL_CORES <<< "${STR_LIST}"

# Initial wait
sleep 30

START=$(date +%s%N)

NAME="IS"
TIMESTAMPS_FILE=${LOG_DIR}/IS.timestamps
run_npb_omp_kernel "bin/is.C.x" "${SEQUENTIAL_CORES[@]}"

sleep 10

NAME="FT"
TIMESTAMPS_FILE=${LOG_DIR}/FT.timestamps
run_npb_omp_kernel "bin/ft.C.x" "${SEQUENTIAL_CORES[@]}"

sleep 10

NAME="MG"
TIMESTAMPS_FILE=${LOG_DIR}/MG.timestamps
run_npb_omp_kernel "bin/mg.C.x" "${SEQUENTIAL_CORES[@]}"

sleep 10

NAME="CG"
TIMESTAMPS_FILE=${LOG_DIR}/CG.timestamps
run_npb_omp_kernel "bin/cg.C.x" "${SEQUENTIAL_CORES[@]}"

sleep 10

NAME="BT"
TIMESTAMPS_FILE=${LOG_DIR}/BT.timestamps
run_npb_omp_kernel "bin/bt.C.x" "${SEQUENTIAL_CORES[@]}"

sleep 10

NAME="BT_IO"
TIMESTAMPS_FILE=${LOG_DIR}/BT_IO.timestamps
run_npb_mpi_kernel "bin/bt.C.x.ep_io" "${SEQUENTIAL_CORES[@]}"

END=$(date +%s%N)
NAME="TOTAL"
print_time START END