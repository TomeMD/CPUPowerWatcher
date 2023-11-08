#!/bin/bash

export BIN_DIR="${GLOBAL_HOME}"/bin
export CONF_DIR="${GLOBAL_HOME}"/etc
export TOOLS_DIR="${GLOBAL_HOME}"/tools
export LOG_FILE=${LOG_DIR}/${WORKLOAD}.log

export GLANCES_HOME="${TOOLS_DIR}"/cpu_power_monitor/glances
export CPUFREQ_HOME="${TOOLS_DIR}"/cpu_power_monitor/cpufreq
export RAPL_HOME="${TOOLS_DIR}"/cpu_power_monitor/rapl
export STRESS_HOME="${TOOLS_DIR}"/stress-system
export STRESS_CONTAINER_DIR="${STRESS_HOME}"/container
export SYSBENCH_HOME="${TOOLS_DIR}"/sysbench
export FIO_HOME="${TOOLS_DIR}"/fio
export NPB_HOME="${TOOLS_DIR}"/NPB3.4.2
export NPB_OMP_HOME="${NPB_HOME}"/NPB3.4-OMP
export NPB_MPI_HOME="${NPB_HOME}"/NPB3.4-MPI
export GEEKBENCH_HOME="${TOOLS_DIR}"/Geekbench-"${GEEKBENCH_VERSION}"-Linux
export SPARK_HOME="${TOOLS_DIR}"/spark-${SPARK_VERSION}-bin-hadoop"${SPARK_VERSION:0:1}"
export SMUSKET_HOME="${TOOLS_DIR}"/smusket
export PYTHON_HOME="$(which python3)"
export JAVA_HOME="$(dirname $(dirname $(readlink -f $(which java))))"

export PHY_CORES_PER_CPU=$(lscpu | grep "Core(s) per socket:" | awk '{print $4}')
export SOCKETS=$(lscpu | grep "Socket(s):" | awk '{print $2}')