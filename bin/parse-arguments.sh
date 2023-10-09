#!/bin/bash

function usage {
  cat << EOF
Usage: $(basename "$0") [OPTIONS]
  -v, --os-virt             Technology for OS-level virtualization. [Default]
                                docker
                                apptainer

  -w, --workload            Workload to stress the system with. [Default: stress-system]
                              npb                 Run NPB kenerls.
                              geekbench           Run Geekbench kenerls.
                              spark               Run Apache Spark.
                              stress-system       Run stress tests using stress-system tool. Options:
                                --stressors              Comma-separated list of stressors to run with stress-system.
                                                         [Default: cpu]
                                --stress-load-types      Comma-separated list of types of load to stress the CPU.
                                                         Used together with CPU stressor. [Default: all]

  -o, --output <dir>       Directory (absolute path) to store log files. [Default: ./log]
  -h, --help               Show this help and exit
EOF
exit 1
}

while [[ $# -gt 0 ]]; do
  case $1 in
    -v|--os-virt)
      OS_VIRT="$2"
      shift 2
      ;;
    -w|--workload)
      WORKLOAD="$2"
      shift 2
      ;;
    --stressors)
      STRESSORS="$2"
      shift 2
      ;;
    --stress-load-types)
      LOAD_TYPES="$2"
      shift 2
      ;;
    -o|--output)
      LOG_DIR="$2"
      shift 2
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

mkdir -p "${LOG_DIR}"