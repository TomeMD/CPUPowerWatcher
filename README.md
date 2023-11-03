# TSG_StressCPU

Set of scripts to automate CPU monitoring and time series storage while running stress tests. Options:

````shell
~$ ./run.sh --help

Usage: run.sh [OPTIONS]
  -v, --os-virt             Technology for OS-level virtualization. [Default]
                                docker
                                apptainer
  -i, --influxdb-host       InfluxDB host to send metrics. [Default: montoxo.des.udc.es]
  -b, --influxdb-bucket     InfluxDB bucket to store metrics. [Default: glances]
  -w, --workload            Workload to stress the system with. [Default: stress-system]
                              npb                 Run NPB kenerls.
                              sysbench            Run Sysbench kernels.
                              geekbench           Run Geekbench kenerls.
                              spark               Run Spark-based DNA error correction algorithm (SMusket) using 
                                                  Spark Standalone.
                              stress-system       Run stress tests using stress-system tool. Options:
                                --stressors              Comma-separated list of stressors to run with stress-system.
                                                         [Default: cpu]
                                --stress-load-types      Comma-separated list of types of load to stress the CPU.
                                                         Used together with CPU stressor. [Default: all]
                                --other-options          Comma-separated list of other stress-ng options specified
                                                         in key=value format.
  --add-io-noise <target>  Run fio to do random reads/writes over <target> while running the specified workload.
  -o, --output <dir>       Directory (absolute path) to store log files. [Default: ./log]
  -h, --help               Show this help and exit
````





