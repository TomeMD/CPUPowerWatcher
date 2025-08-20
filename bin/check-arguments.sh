#!/usr/bin/env bash

SUPPORTED_OS_VIRT=("docker" "apptainer")
SUPPORTED_WORKLOADS=("stress-system" "npb" "fio" "spark" "sysbench" "geekbench")
SUPPORTED_PATTERNS=("stairs-up" "stairs-down" "zigzag" "uniform" "udrt")
IDLE_SENSITIVE_PATTERNS=("uniform" "udrt")
declare -A SOCKET_SUPPORTED_DISTRIBUTIONS=(
  [single-socket]="Single_Core,Group_P,Group_P_and_L,Group_1P_2L"
  [multi-socket]="Single_Core,Group_P,Spread_P,Group_P_and_L,Group_1P_2L,Group_PP_LL,Spread_P_and_L,Spread_PP_LL"
)

# First print logo to avoid hiding warnings
show_logo

########################################################################################################################
# GENERAL CHECKS
########################################################################################################################
if [ "${SOCKETS}" -gt "2" ] ; then
  m_err "Number of sockets (${SOCKETS}) not supported. Number of sockets must be 1 or 2"
  exit 1
fi

if [ "${CUSTOM_TESTS}" -eq "1" ] && [ ! -f "${CUSTOM_TESTS_FILE}" ]; then
  m_err "Provided custom tests file doesn't exists: ${CUSTOM_TESTS_FILE}"
  exit 1
fi

########################################################################################################################
# OS VIRTUALIZATION TECHNOLOGY
########################################################################################################################
if ! item_is_in_list "${OS_VIRT}" "${SUPPORTED_OS_VIRT[@]}" >> /dev/null 2>&1; then
  m_err "OS Virtualization Technology (${OS_VIRT}) not supported. Supported engines: [${SUPPORTED_OS_VIRT[*]}]"
  exit 1
fi

if ! [ -x "$(command -v "${OS_VIRT}")" ]; then
  m_err "OS Virtualization Technology (${OS_VIRT}) is not installed"
  exit 1
fi

########################################################################################################################
# PYTHON
########################################################################################################################
if [ -x "$(command -v python3)" ]; then
  PYTHON_CMD="$(readlink -f $(which python3))"
elif [ -x "$(command -v python)" ]; then
  PYTHON_CMD="$(readlink -f $(which python))"
fi

if [ -z "${PYTHON_CMD}" ]; then
  m_err "Python is not installed. You must install python to use CPUPowerWatcher"
  exit 1
fi

PYTHON_VERSION=$("${PYTHON_CMD}" --version 2>&1 | awk '{print $2}')
if [ "${PYTHON_VERSION:0:1}" != "3" ]; then
  m_warn "Python3 is not installed (available version is ${PYTHON_VERSION}). This may cause unexpected behaviour when using stress-system (UDRT) or spark workloads."
fi

########################################################################################################################
# INFLUXDB
########################################################################################################################
if ! ping -c 1 "${INFLUXDB_HOST}" &> /dev/null; then
  m_err "InfluxDB host (${INFLUXDB_HOST}) is not reachable"
  exit 1
fi

########################################################################################################################
# WORKLOADS
########################################################################################################################
if ! item_is_in_list "${WORKLOAD}" "${SUPPORTED_WORKLOADS[@]}" >> /dev/null 2>&1; then
  m_err "Workload (${WORKLOAD}) not supported. Supported workloads [${SUPPORTED_WORKLOADS[*]}]"
  exit 1
fi

########################################################################################################################
# STRESS-SYSTEM
########################################################################################################################
if [ "${WORKLOAD}" == "stress-system" ]; then
  # Check CPU topology is supported
  if [ "${SOCKETS}" -gt "2" ]; then
    m_err "Number of sockets (${SOCKETS}) not yet supported for ${WORKLOAD}. Aborting tests..."
    exit 1
  fi

  # Check supported core distributions for current CPU topology
  IFS=',' read -r -a SUPPORTED_DISTRIBUTIONS <<< "${SOCKET_SUPPORTED_DISTRIBUTIONS[${CPU_TOPOLOGY}]}"
  if [ "${CORE_DISTRIBUTIONS}" == "all" ]; then
    FINAL_CORE_DISTRIBUTIONS=("${SUPPORTED_DISTRIBUTIONS[@]}")
  else
    # Get all of the user-defined core distributions that are supported for current CPU topology
    IFS=',' read -ra CORE_DIST_ARRAY <<< "${CORE_DISTRIBUTIONS}"
    for CORE_DIST in "${CORE_DIST_ARRAY[@]}"; do
      if item_is_in_list "${CORE_DIST}" "${SUPPORTED_DISTRIBUTIONS[@]}" >> /dev/null 2>&1; then
        FINAL_CORE_DISTRIBUTIONS+=("${CORE_DIST}")
      else
        m_warn "Core distribution ${CORE_DIST} not supported. It will be ignored..."
      fi
    done
    # Check that at least one of the specified core distributions is supported
    if [ ${#FINAL_CORE_DISTRIBUTIONS[@]} -eq 0 ]; then
      m_err "Any of the specified core distributions is supported for ${CPU_TOPOLOGY} CPUs. Supported distributions: [${SUPPORTED_DISTRIBUTIONS[*]}]"
      exit 1
    fi
  fi

  # Check supported patterns
  if ! item_is_in_list "${STRESS_PATTERN}" "${SUPPORTED_PATTERNS[@]}" >> /dev/null 2>&1; then
      m_err "Pattern (${STRESS_PATTERN}) not supported. Supported patterns [${SUPPORTED_PATTERNS[*]}]"
      exit 1
  fi

  if [ "${STRESS_TIME}" -le "0" ] ; then
    m_err "Time under stress must be a positive number greater than zero (current value is ${STRESS_TIME})"
    exit 1
  fi

  if [ "${IDLE_TIME}" -lt "0" ] ; then
    m_err "CPU idle time between tests can't be negative (current value is ${IDLE_TIME})"
    exit 1
  fi

  SENSITIVE=$(item_is_in_list "${STRESS_PATTERN}" "${IDLE_SENSITIVE_PATTERNS[@]}")
  if [ "${SENSITIVE}" -eq "0" ]  && [ "${IDLE_TIME}" -gt "0" ]; then
    m_warn "Idle time must be 0 when using pattern ${STRESS_PATTERN} (if greater than 0 it adds bias to the distribution). Trimming idle time from ${IDLE_TIME} to 0."
    IDLE_TIME=0
  fi
fi

########################################################################################################################
# APACHE SPARK (SMUSKET)
########################################################################################################################
if [ "${WORKLOAD}" == "spark" ]; then
  if [ ! -d "${SPARK_DATA_DIR}" ]; then
    m_err "Specified Spark Data directory doesn't exist: ${SPARK_DATA_DIR}"
    exit 1
  fi
  PYTHON_HOME="${PYTHON_CMD}"
  JAVA_HOME="$(dirname $(dirname $(readlink -f $(which java))))"
  if [ -z "${JAVA_HOME}" ]; then
    m_err "JAVA_HOME is not set. You must set JAVA_HOME to use Spark, Please check Java is installed."
    exit 1
  fi
fi

########################################################################################################################
# FIO
########################################################################################################################
if [ "${WORKLOAD}" == "fio" ] && [ "${ADD_IO_NOISE}" -ne "0" ]; then
  m_warn "It's not consistent to use fio with I/O noise because both run fio"
fi
