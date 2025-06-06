#!/usr/bin/env bash

function usage {
  cat << EOF
Usage: $(basename "$0") [OPTIONS]
  -v, --os-virt             Technology for OS-level virtualization. [Default: apptainer]
                                docker
                                apptainer
  -i, --influxdb-host       InfluxDB host to send metrics. [Default: montoxo.des.udc.es]
  -b, --influxdb-bucket     InfluxDB bucket to store metrics. [Default: public]
  -o, --output <dir>        Directory (absolute path) to store log files. [Default: ./log]
  -w, --workload            Workload to stress the system with. [Default: stress-system]
                              npb                 Run NPB kenerls.
                              sysbench            Run Sysbench kernels.
                              geekbench           Run Geekbench kenerls.
                              fio                 Run fio to make random reads/writes over specified target with
                                                  different numbers of threads.
                                --fio-target      Directory to make random reads/writes. [Default: /tmp/fio]

                              spark               Run Spark-based DNA error correction algorithm (SMusket) using
                                                  Spark Standalone.
                                --spark-data-dir  Directory to store Spark temporary files and Spark Smusket input.
                                                  Input must be a FASTQ file named "input.fastq".

                              stress-system       Run stress tests using stress-system tool and different core
                                                  distributions. In addition, the tool can follow different patterns
                                                  to gradually use all cores from core distribution. Options:
                                --stressors              Comma-separated list of stressors to run with stress-system.
                                                         [Default: cpu]
                                --core-distributions     Comma-separated list of core distributions, which represent the order
                                                         followed by the tool when selecting cores to achieve a desired CPU load level.
                                                         The supported core distributions depend on the CPU topology.
                                                         [Default: all]
                                --stress-pattern         Pattern followed to get groups of cores from the core distribution.
                                                         Patterns: stairs-up, stairs-down, zigzag, uniform or udrt [Default: stairs-up]
                                --stress-time            Time (in seconds) under stress for each group of cores.
                                                         [Default: 120]
                                --idle-time              Time (in seconds) to keep the CPU idle between one group of
                                                         cores and the next one. [Default: 20]
                                --stress-load-types      Comma-separated list of types of load to stress the CPU.
                                                         Used together with CPU stressor. [Default: all]
                                --stress-extra-options   Comma-separated list of other stress-ng options specified
                                                         in key=value format.

  --base                   Get base measurements before tests to have idle consumption and overhead metrics.
  --add-io-noise           Run fio to make random reads/writes over specified target while running the specified
                           workload. Use --fio-target to specify target directory. This option is not compatible with
                           fio tests.
  --custom-tests <file>    Use custom tests file to create custom lists of cores to stress.
                           [Default: ./bin/test/stress-tests-custom.sh]
  -h, --help               Show this help and exit
EOF
exit 1
}

while [[ $# -gt 0 ]]; do
  case $1 in
    -v|--os-virt)
      OS_VIRT="${2}"
      shift 2
      ;;
    -i|--influxdb-host)
      INFLUXDB_HOST="${2}"
      shift 2
      ;;
    -b|--influxdb-bucket)
      INFLUXDB_BUCKET="${2}"
      shift 2
      ;;
    -w|--workload)
      WORKLOAD="${2}"
      shift 2
      ;;
    --fio-target)
      FIO_TARGET="${2}"
      shift 2
      ;;
    --spark-data-dir)
      SPARK_DATA_DIR="${2}"
      shift 2
      ;;
    --stressors)
      STRESSORS="${2}"
      shift 2
      ;;
    --core-distributions)
      CORE_DISTRIBUTIONS="${2}"
      shift 2
      ;;
    --stress-pattern)
      STRESS_PATTERN="${2}"
      shift 2
      ;;
    --stress-time)
      STRESS_TIME="${2}"
      shift 2
      ;;
    --idle-time)
      IDLE_TIME="${2}"
      shift 2
      ;;
    --stress-load-types)
      LOAD_TYPES="${2}"
      shift 2
      ;;
    --stress-extra-options)
      STRESS_EXTRA_OPTS="--other ${2} "
      IFS=',' read -ra STRESS_EXTRA_OPTS_ARRAY <<< "${2}"
      shift 2
      ;;
    -o|--output)
      LOG_DIR="${2}"
      shift 2
      ;;
    --base)
      GET_BASE_MEASUREMENTS=1
      shift 1
      ;;
    --add-io-noise)
      ADD_IO_NOISE=1
      shift 1
      ;;
    --custom-tests)
      CUSTOM_TESTS=1
      if [ -n "${2}" ];then
        CUSTOM_TESTS_FILE="${2}"
        shift 2
      else
        shift 1
      fi
      ;;
    -h|--help)
      usage
      ;;
    *)
    echo "Unknown option: ${1}"
      exit 1
      ;;
  esac
done

mkdir -p "${LOG_DIR}"