#!/bin/bash

function usage {
  cat << EOF
Usage: $(basename "$0") [OPTIONS]

OS-LEVEL VIRTUALIZATION:
  -d, --docker             Use Docker for OS-level virtualization. [Default]
  -a, --apptainer          Use Apptainer for OS-level virtualization.

WORKLOAD:
  -s, -stress-system       Run stress tests using stress-system tool. [Default]
      --stressors              Comma-separated list of stressors to run with stress-system. [Default: cpu]
      --stress-load-types      Comma-separated list of types of load to stress the CPU. Used together with CPU stressor. [Default: all]
  -n, --npb                Run NPB kenerls.
  -g, --geekbench          Run Geekbench kenerls.

GLOBAL OPTIONS:
  -o, --output <dir>       Directory (absolute path) to store log files. [Default: ./log]
  -h, --help               Show this help and exit
EOF
exit 1
}

while [[ $# -gt 0 ]]; do
  case $1 in
    -o|--output)
      LOG_DIR="$2"
      shift 2
      ;;
    -d|--docker)
      OS_VIRT="docker"
      shift 1
      ;;
    -a|--apptainer)
      OS_VIRT="apptainer"
      shift 1
      ;;
    -s|--stress-tests)
      WORKLOAD="stress-system"
      shift 1
      ;;
    --stressors)
      STRESSORS="$2"
      shift 2
      ;;
    --stress-load-types)
      LOAD_TYPES="$2"
      shift 2
      ;;
    -n|--npb)
      WORKLOAD="npb"
      shift 1
      ;;
    -g|--geekbench)
      WORKLOAD="geekbench"
      shift 1
      ;;
    -h|--help)
      usage
      ;;
    *)
    echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

