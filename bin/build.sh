#!/bin/bash

# Set monitoring environment
cd cpu_power_monitor
sed -i '/\[influxdb2\]/,/\[/{s/^host=localhost$/host=montoxo.des.udc.es/}' glances/etc/glances.conf
sed -i '/ic_influx_database/s/localhost/montoxo.des.udc.es/' rapl/src/rapl_plot/rapl_plot.c
if [ "$OS_VIRT" == "docker" ]; then
  echo "Building Glances..."
  docker build -t glances ./glances
  echo "Building RAPL..."
  docker build -t rapl ./rapl
else
  echo "Building Glances..."
  cd glances && apptainer build glances.sif glances.def > /dev/null && cd ..
  echo "Building RAPL..."
  cd rapl && apptainer build rapl.sif rapl.def > /dev/null && cd ..
fi
cd ..


# Set stress tool
cd stress-system
chmod +x run.sh
echo "Building stress-system..."
if [ "$OS_VIRT" == "docker" ]; then
  docker build -t stress-system -f container/Dockerfile .
else
  cd container && apptainer build stress.sif stress.def > /dev/null && cd ..
fi
cd ..

if [ "$WORKLOAD" == "npb" ]; then
	if [ ! -d "NPB3.4.2" ]; then
		echo "Downloading NPB kernels..."
		wget https://www.nas.nasa.gov/assets/npb/NPB3.4.2.tar.gz
		tar -xf NPB3.4.2.tar.gz
		rm NPB3.4.2.tar.gz
		cd NPB3.4.2/NPB3.4-OMP
		cp config/make.def.template config/make.def
		make is CLASS=C
		make ft CLASS=C
		make mg CLASS=C
		make cg CLASS=C
		make bt CLASS=C
		cd ../..
	else
		echo "NPB kernels were already downloaded"
	fi
elif [ "$WORKLOAD" == "geekbench" ]; then
	if [ ! -d "Geekbench-${GEEKBENCH_VERSION}-Linux" ]; then
		echo "Downloading Geekbench..."
		wget https://cdn.geekbench.com/Geekbench-${GEEKBENCH_VERSION}-Linux.tar.gz
		tar -xf Geekbench-${GEEKBENCH_VERSION}-Linux.tar.gz
		rm Geekbench-${GEEKBENCH_VERSION}-Linux.tar.gz
	else
		echo "Geekbench was already downloaded"
	fi
fi
