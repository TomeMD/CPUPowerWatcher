#!/bin/bash

export OUTPUT_DIR=log/
export RUN_NPB=1
export RUN_GEEKBENCH=1
export USE_DOCKER=0
export GEEKBENCH_VERSION="5.4.1"

. ./bin/parse-arguments.sh

# Build environment
echo "Building environment"
./bin/build.sh
echo "Environment is ready"

if [ "$RUN_NPB" -eq "0" ]; then
  echo "Running NPB tests..."
  . ./bin/init.sh
  . ./bin/npb-tests.sh
  . ./bin/finish.sh
elif [ "$RUN_GEEKBENCH" -eq "0" ]; then
  echo "Running Geekbench tests..."
  . ./bin/init.sh
  . ./bin/geekbench-tests.sh
  . ./bin/finish.sh 
else
  echo "Running stress tests..."
  SOCKETS=$(lscpu | grep "Socket(s):" | awk '{print $2}')
  if [ "$SOCKETS" -eq "1" ]; then
    . ./bin/init.sh
    . ./bin/stress-tests-singlesocket.sh
  elif [ "$SOCKETS" -eq "2" ]; then
    . ./bin/init.sh
    . ./bin/stress-tests-multisocket.sh
  else
    echo "Number of sockets ($SOCKETS) not supported"
    echo "Aborting tests..."
    exit 1
  fi
  . ./bin/finish.sh
  echo "Stress tests finished successfully"
fi
