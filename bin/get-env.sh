#!/bin/bash

export LOG_DIR="${GLOBAL_HOME}"/log
export BIN_DIR="${GLOBAL_HOME}"/bin
export CONF_DIR="${GLOBAL_HOME}"/etc

export GLANCES_HOME="${GLOBAL_HOME}"/cpu_power_monitor/glances
export CPUFREQ_HOME="${GLOBAL_HOME}"/cpu_power_monitor/cpufreq
export RAPL_HOME="${GLOBAL_HOME}"/cpu_power_monitor/rapl
export STRESS_HOME="${GLOBAL_HOME}"/stress-system
export STRESS_CONTAINER_DIR="${STRESS_HOME}"/container
export NPB_HOME="${BIN_DIR}"/NPB3.4.2/NPB3.4-OMP
export GEEKBENCH_HOME="${BIN_DIR}"/Geekbench-"${GEEKBENCH_VERSION}"-Linux

export PHY_CORES_PER_CPU=$(lscpu | grep "Core(s) per socket:" | awk '{print $4}')
export SOCKETS=$(lscpu | grep "Socket(s):" | awk '{print $2}')