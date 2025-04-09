#!/bin/bash
#
#SBATCH --nodes 1
#SBATCH --exclusive
#SBATCH --overcommit
#SBATCH --ntasks=100
#SBATCH -o my_job_%j.out

# Load modules
module load gnu8
module load openmpi4

SCRIPT_PATH=$(scontrol show job "${SLURM_JOB_ID}" | grep 'Command=' | cut -d "=" -f 2)
PLATFORM_HOME=$(dirname -- "$(dirname -- "${SCRIPT_PATH}")")
LOG_DIR="${PLATFORM_HOME}/log"

# Debug info
echo "SCRIPT_PATH=${SCRIPT_PATH}"
echo "PLATFORM_HOME=${PLATFORM_HOME}"
echo "LOG_DIR=${LOG_DIR}"

# Define here the parameters CPUPowerWatcher should use for each test
declare -A TEST_PARAMS
TEST_PARAMS["all"]="--base -v apptainer -w stress-system"
TEST_PARAMS["sysinfo"]="-v apptainer -w stress-system --stressors sysinfo"
TEST_PARAMS["sysinfo_all"]="-v apptainer -w stress-system --stressors cpu,sysinfo"
TEST_PARAMS["iomix"]="-v apptainer -w stress-system --stressors iomix --stress-extra-options temp-path=/scratch2"
TEST_PARAMS["smusket"]="-v apptainer -w spark --spark-data-dir /scratch/ssd/spark-data"
TEST_PARAMS["npb"]="-v apptainer -w npb"

# Put here the tests you want to run
TESTS=("all" "sysinfo" "sysinfo_all" "iomix")

# Run tests
for TEST in "${TESTS[@]}"; do
    TEST_LOG_DIR="${LOG_DIR}/${SLURM_JOB_PARTITION}/${TEST}"
    TEST_LOG_FILE="${TEST_LOG_DIR}/CPUPowerWatcher.log"

    # Create output directory for current test
    mkdir -p "${TEST_LOG_DIR}"

    echo "Running test ${TEST} and saving logs to ${TEST_LOG_DIR}"

    # Run test
    "${PLATFORM_HOME}/run.sh" -b "${SLURM_JOB_PARTITION}" -o "${TEST_LOG_DIR}" ${TEST_PARAMS[${TEST}]} > "${TEST_LOG_FILE}" 2>&1

    echo "Test ${TEST} finished"

    # Sleep between tests
    sleep 600
done