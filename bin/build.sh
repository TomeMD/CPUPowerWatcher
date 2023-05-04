#!/bin/bash

cd bin

# Download and set monitoring environment
if [ ! -d "glances_influxdb_grafana" ]; then
	echo "Installing monitong environment..."
	git clone https://github.com/TomeMD/glances_influxdb_grafana.git
	cd glances_influxdb_grafana
	sed -i '/\[influxdb2\]/,/\[/{s/^host=localhost$/host=montoxo.des.udc.es/}' glances/etc/glances.conf
	sed -i '/ic_influx_database/s/localhost/montoxo.des.udc.es/' rapl/src/rapl_plot/rapl_plot.c
	if [ "$USE_DOCKER" -eq "0" ]; then
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
else
	echo "Monitoring environment was already installed"
fi

# Set stress tool
if [ ! -d "stress-system" ]; then
	echo "Installing stress tool..."
	git clone https://github.com/TomeMD/stress-system.git
	cd stress-system
	chmod +x run.sh
	echo "Building stress-system..."
	if [ "$USE_DOCKER" -eq "0" ]; then
		docker build -t stress-system -f container/Dockerfile .
	else
		cd container && apptainer build stress.sif stress.def > /dev/null && cd ..
	fi
	cd ..
else
	echo "Stress tool was already installed"
fi

if [ "$RUN_NPB" -eq "0" ]; then
	if [ ! -d "NPB3.4.2" ]; then
		echo "Downloading NPB kernels..."
		wget https://www.nas.nasa.gov/assets/npb/NPB3.4.2.tar.gz
		tar -xf NPB3.4.2.tar.gz
		rm NPB3.4.2.tar.gz
		cd NPB3.4.2/NPB3.4-OMP
		cp config/make.def.template config/make.def
		make cg CLASS=C
		make ft CLASS=C
		make mg CLASS=C
		make bt CLASS=C
		cd .. && cd ..
	else
		echo "NPB kernels were already downloaded"
	fi
fi

cd ..
