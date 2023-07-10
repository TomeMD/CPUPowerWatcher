#!/bin/bash

function usage {
  cat << EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -d, --docker <0-or-1>    Set to 0 to use Docker or 1 to use Apptainer. [Default: 0]
  -n, --npb <T>            Set 0 for running NPB kenerls instead of running stress-tests [Default: 1]
  -g, --geekbench <T>      Set 0 for running Geekbench kenerls instead of running stress-tests [Default: 1]
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
      USE_DOCKER="$2"
      shift 2
      ;;
    -n|--npb)
      RUN_NPB="$2"
      shift 2
      ;;
    -g|--geekbench)
      RUN_GEEKBENCH="$2"
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

