#!/bin/bash

export OUTPUT_DIR=log/
export OS_VIRT="docker"
export WORKLOAD="stress-tests"
export GEEKBENCH_VERSION="5.4.1"
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
