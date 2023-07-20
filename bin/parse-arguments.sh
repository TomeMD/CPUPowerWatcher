#!/bin/bash

function usage {
  cat << EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -d, --docker             Use Docker for OS-level virtualization. [Default]
  -a, --apptainer          Use Apptainer for OS-level virtualization.
  -s, -stress-tests        Run stress tests using stress-system tool. [Default]
  -n, --npb                Run NPB kenerls.
  -g, --geekbench          Run Geekbench kenerls.
  -o, --output <dir>       Directory to store log files. [Default: ./log]      
  -h, --help               Show this help and exit
EOF
exit 1
}

while [[ $# -gt 0 ]]; do
  case $1 in
    -o|--output)
      OUTPUT_DIR="$2"
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
      WORKLOAD="stress-tests"
      shift 1
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

