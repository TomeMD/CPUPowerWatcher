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
export SPARK_HOME="${BIN_DIR}"/spark-${SPARK_VERSION}-bin-hadoop"${SPARK_HADOOP_VERSION}"
export SPARK_EXAMPLES_JAR="${SPARK_HOME}"/examples/jars/spark-examples_2.12-3.2.0.jar
export SPARK_MASTER_URL=spark://localhost:7077
export PYTHON_HOME=$(which python3)
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))

export PHY_CORES_PER_CPU=$(lscpu | grep "Core(s) per socket:" | awk '{print $4}')
export SOCKETS=$(lscpu | grep "Socket(s):" | awk '{print $2}')