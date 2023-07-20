#!/bin/bash

# Set environment
export STRESS_HOME=`dirname $0`
export BIN_DIR=${STRESS_HOME}/bin
export CONF_DIR=${STRESS_HOME}/etc
export EXP_DIR=${STRESS_HOME}/experiment
export OUT_DIR=${STRESS_HOME}/out/report_$(date '+%d_%m_%Y_%H-%M-%S')
mkdir -p $OUT_DIR
export LOG_FILE=${OUT_DIR}/log
export CORE_FILE=${OUT_DIR}/core

# Load bash functions
. ${BIN_DIR}/functions.sh

# Load default values
. ${CONF_DIR}/stress-default.sh

# Load configuration file 
. ${EXP_DIR}/stress-conf.sh

# Parse arguments
. ${BIN_DIR}/parse-arguments.sh

# Run tests
. ${BIN_DIR}/run-tests.sh