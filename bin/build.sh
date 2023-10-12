#!/bin/bash

print_conf

m_echo "Building monitoring environment"

# Set InfluxDB Server
sed -i "/\[influxdb2\]/,/\[/{s/^host=localhost$/host=${INFLUXDB_HOST}/}" "${GLANCES_HOME}"/etc/glances.conf
sed -i "/ic_influx_database/s/localhost/${INFLUXDB_HOST}/" "${RAPL_HOME}"/src/rapl_plot/rapl_plot.c

# Build monitoring environment
if [ "${OS_VIRT}" == "docker" ]; then
  if [ -z "$(docker image ls -q glances)" ]; then
    m_echo "Building Glances..."
    docker build -t glances "${GLANCES_HOME}"
  else
    m_echo "Glances image already exists. Skipping build."
  fi
  if [ -z "$(docker image ls -q rapl)" ]; then
    m_echo "Building RAPL..."
    docker build -t rapl "${RAPL_HOME}"
  else
    m_echo "RAPL image already exists. Skipping build."
  fi
elif [ "${OS_VIRT}" == "apptainer" ]; then
  if [ ! -f "${GLANCES_HOME}"/glances.sif ]; then
    m_echo "Building Glances..."
    cd "${GLANCES_HOME}" && apptainer build -F glances.sif glances.def
  else
    m_echo "Glances image already exists. Skipping build."
  fi
  if [ ! -f "${RAPL_HOME}"/rapl.sif ]; then
    m_echo "Building RAPL..."
    cd "${RAPL_HOME}" && apptainer build -F rapl.sif rapl.def
  else
    m_echo "RAPL image already exists. Skipping build."
  fi
fi

cd "${GLOBAL_HOME}"
chmod +x "${CPUFREQ_HOME}"/get-freq-core.sh

# Compile workloads
if [ "${WORKLOAD}" == "stress-system" ]; then # STRESS-SYSTEM
  chmod +x "${STRESS_HOME}"/run.sh
  if [ "$OS_VIRT" == "docker" ]; then
    if [ -z "$(docker image ls -q stress-system)" ]; then
      m_echo "Building stress-system..."
      cd "${STRESS_HOME}" && docker build -t stress-system -f "${STRESS_CONTAINER_DIR}"/Dockerfile .
    else
      m_echo "Stress-system image already exists. Skipping build."
    fi
  elif [ "${OS_VIRT}" == "apptainer" ]; then
    if [ ! -f "${STRESS_CONTAINER_DIR}"/stress.sif ]; then
      m_echo "Building stress-system..."
      cd "${STRESS_CONTAINER_DIR}" && apptainer build -F stress.sif stress.def > /dev/null
    else
      m_echo "Stress-system image already exists. Skipping build."
    fi
  fi

elif [ "${WORKLOAD}" == "npb" ]; then # NPB KERNELS
	if [ ! -d "${NPB_HOME}" ]; then
		m_echo "Downloading NPB kernels..."
		wget https://www.nas.nasa.gov/assets/npb/NPB3.4.2.tar.gz
		tar -xf NPB3.4.2.tar.gz -C "${TOOLS_DIR}"
		rm NPB3.4.2.tar.gz
		cd "${NPB_HOME}"
		cp config/make.def.template config/make.def
		make clean
		make is CLASS=C
		make ft CLASS=C
		make mg CLASS=C
		make cg CLASS=C
		make bt CLASS=C
	else
		m_echo "NPB kernels were already downloaded"
	fi

elif [ "${WORKLOAD}" == "sysbench" ]; then # SYSBENCH
  if [ "$OS_VIRT" == "docker" ]; then
    if [ -z "$(docker image ls -q sysbench)" ]; then
      m_echo "Building sysbench..."
      cd "${SYSBENCH_HOME}" && docker build -t sysbench .
    else
      m_echo "Sysbench image already exists. Skipping build."
    fi
  elif [ "${OS_VIRT}" == "apptainer" ]; then
    if [ ! -f "${SYSBENCH_HOME}"/sysbench.sif ]; then
      m_echo "Building sysbench..."
      cd "${SYSBENCH_HOME}" && apptainer build -F sysbench.sif sysbench.def > /dev/null
    else
      m_echo "Sysbench image already exists. Skipping build."
    fi
  fi

elif [ "${WORKLOAD}" == "geekbench" ]; then # GEEKBENCH
	if [ ! -d "${GEEKBENCH_HOME}" ]; then
		m_echo "Downloading Geekbench..."
		wget https://cdn.geekbench.com/Geekbench-"${GEEKBENCH_VERSION}"-Linux.tar.gz
		tar -xf Geekbench-"${GEEKBENCH_VERSION}"-Linux.tar.gz -C "${TOOLS_DIR}"
		rm Geekbench-"${GEEKBENCH_VERSION}"-Linux.tar.gz
	else
		m_echo "Geekbench was already downloaded"
	fi

elif [ "${WORKLOAD}" == "spark" ]; then # APACHE SPARK
	if [ ! -d "${SPARK_HOME}" ]; then
		m_echo "Downloading Apache Spark..."
		if [ -z "${JAVA_HOME}" ]; then
		  m_err "JAVA_HOME is not set"
		  exit 1
		fi
    if [ -z "${PYTHON_HOME}" ]; then
      m_err "Python 3 is not installed"
      exit 1
    fi
		#sudo apt install default-jdk scala git -y
		wget https://archive.apache.org/dist/spark/spark-"${SPARK_VERSION}"/spark-"${SPARK_VERSION}"-bin-hadoop"${SPARK_HADOOP_VERSION}".tgz
		tar -xf spark-"${SPARK_VERSION}"-bin-hadoop3.2.tgz -C "${TOOLS_DIR}"
		rm spark-"${SPARK_VERSION}"-bin-hadoop3.2.tgz
		echo "export SPARK_HOME=${SPARK_HOME}" >> ~/.bashrc
		echo "export JAVA_HOME=${JAVA_HOME}" >> ~/.bashrc
    echo "export PATH=${PATH}:${SPARK_HOME}/bin:${SPARK_HOME}/sbin" >> ~/.bashrc
    echo "export PYSPARK_PYTHON=${PYTHON_HOME}" >> ~/.bashrc
    source ~/.bashrc
	else
		m_echo "Apache Spark was already downloaded"
	fi
fi

cd "${GLOBAL_HOME}"
