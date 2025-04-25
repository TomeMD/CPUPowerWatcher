#!/bin/bash

export GLOBAL_HOME=$(dirname -- "$(readlink -f -- "${BASH_SOURCE}")")

# Get initial configuration
. "${GLOBAL_HOME}"/etc/default-conf.sh
. "${GLOBAL_HOME}"/bin/parse-arguments.sh
. "${GLOBAL_HOME}"/bin/get-env.sh
. "${BIN_DIR}"/functions.sh
. "${BIN_DIR}"/check-arguments.sh

# Build environment
. "${BIN_DIR}"/build.sh

cleanup() {
  if [ "${CLEANUP_DONE}" -eq 0 ]; then
    CLEANUP_DONE=1
    kill 0 && "${GLOBAL_HOME}/bin/finish.sh"
    m_warn "CLEANUP HAS BEEN CALLED (ENVIRONMENT WAS CLOSED AFTER SIGTERM OR SIGINT)"
  fi
}

# Capture SIGINT (Ctrl-C) and SIGTERM (kill)
trap cleanup SIGINT SIGTERM
CLEANUP_DONE=0

(
  # Run workload
  . "${BIN_DIR}"/run-workload.sh

  # Close environment
  . "${BIN_DIR}"/finish.sh
) &

wait $!
