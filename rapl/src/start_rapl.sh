#!/bin/sh

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib
export PATH=$PATH:$RAPL_BIN

echo "Starting RAPL monitor"
/var/lib/rapl/rapl_plot/rapl_plot
