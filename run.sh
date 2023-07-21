#!/bin/bash

export OUTPUT_DIR=log/
export OS_VIRT="docker"
export WORKLOAD="stress-tests"
export GEEKBENCH_VERSION="5.4.1"
export GLOBAL_HOME=`dirname $0`
export GLANCES_HOME=cpu_power_monitor/glances
export CPUFREQ_HOME=cpu_power_monitor/cpufreq
export RAPL_HOME=cpu_power_monitor/rapl
export STRESS_HOME=stress-system
export STRESS_CONTAINER_DIR=${STRESS_HOME}/container
export BIN_DIR=${GLOBAL_HOME}/bin
export NPB_HOME=${BIN_DIR}/NPB3.4.2/NPB3.4-OMP
export GEEKBENCH_HOME=${BIN_DIR}/Geekbench-${GEEKBENCH_VERSION}-Linux

SOCKETS=$(lscpu | grep "Socket(s):" | awk '{print $2}')

. ./bin/parse-arguments.sh

# Build environment
echo "Building and initializing environment"
. ./bin/build.sh
. ./bin/init.sh
echo "Environment is ready"

if [ "$WORKLOAD" == "npb" ]; then
  echo "Running NPB tests..."
  . ./bin/npb-tests.sh
elif [ "$WORKLOAD" == "geekbench" ]; then
  echo "Running Geekbench tests..."
  . ./bin/geekbench-tests.sh
else
  echo "Running stress tests..."
  if [ "$SOCKETS" -eq "1" ]; then
    . ./bin/stress-tests-singlesocket.sh
  elif [ "$SOCKETS" -eq "2" ]; then
    . ./bin/stress-tests-multisocket.sh
  else
    echo "Number of sockets ($SOCKETS) not supported"
    echo "Aborting tests..."
  fi
fi

echo "Closing environment"
. ./bin/finish.sh
echo "Environment closed"
