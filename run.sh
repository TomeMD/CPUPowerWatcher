#!/bin/bash

export GLOBAL_HOME=`cd $(dirname "$0"); pwd`

# Get initial configuration
. "${GLOBAL_HOME}"/bin/get-env.sh
. "${CONF_DIR}"/default-conf.sh
. "${BIN_DIR}"/parse-arguments.sh
. "${BIN_DIR}"/functions.sh

# Build environment
. "${BIN_DIR}"/build.sh
#. "${BIN_DIR}"/init.sh

# Run workload
. "${BIN_DIR}"/run-workload.sh

# Close environment
. "${BIN_DIR}"/finish.sh

