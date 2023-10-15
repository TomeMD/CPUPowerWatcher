#!/bin/bash

export BIN_DIR="${GLOBAL_HOME}"/bin
export CONF_DIR="${GLOBAL_HOME}"/etc
export TOOLS_DIR="${GLOBAL_HOME}"/tools

export GLANCES_HOME="${TOOLS_DIR}"/cpu_power_monitor/glances
export CPUFREQ_HOME="${TOOLS_DIR}"/cpu_power_monitor/cpufreq
export RAPL_HOME="${TOOLS_DIR}"/cpu_power_monitor/rapl
export STRESS_HOME="${TOOLS_DIR}"/stress-system
export STRESS_CONTAINER_DIR="${STRESS_HOME}"/container
export SYSBENCH_HOME="${TOOLS_DIR}"/sysbench
export NPB_HOME="${TOOLS_DIR}"/NPB3.4.2/NPB3.4-OMP
export GEEKBENCH_HOME="${TOOLS_DIR}"/Geekbench-"${GEEKBENCH_VERSION}"-Linux
export SPARK_HOME="${TOOLS_DIR}"/spark-${SPARK_VERSION}-bin-hadoop"${SPARK_HADOOP_VERSION}"
export SPARK_EXAMPLES_JAR="${SPARK_HOME}"/examples/jars/spark-examples_2.12-3.2.0.jar
export SPARK_MASTER_HOST=localhost
export SPARK_MASTER_URL=spark://"${SPARK_MASTER_HOST}":7077
export PYTHON_HOME=$(which python3)
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))

export PHY_CORES_PER_CPU=$(lscpu | grep "Core(s) per socket:" | awk '{print $4}')
export SOCKETS=$(lscpu | grep "Socket(s):" | awk '{print $2}')