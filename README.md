# CPUPowerWatcher
CPUPowerWatcher automate CPU monitoring and time series storage while running workloads. 

Supported metrics:
| Metric        | Description                                              |
| ------------- | -------------------------------------------------------- |
| CPU power     | Real-time CPU power consumption measured with `RAPL_PKG` |
| CPU usage     | User, system and iowait CPU load                         |
| CPU frequency | Current operating frequency per core                     |
| CPU C-States  | CPU sleep and idle state information                     |
| CPU voltage   | Core voltage readings from CPU MSRs (vCore)              |

Supported workloads:
| Workload                      | Description                                                  |
| ----------------------------- | ------------------------------------------------------------ |
| NAS Parallel Benchmarks (NPB) | Kernels IS, FT, CG, MG, BT, BT I/O, scaling cores 1, 2, 4, ... to maximum |
| Fio                           | I/O benchmark scaling cores 1, 2, 4, ... to maximum          |
| SMusket                       | DNA error correction using Spark Standalone scaling cores 1, 2, 4, ... to maximum |
| stress-system                 | Run stress-ng using different sets of cores (e.g., 1st cores 1,3,5, then cores 2,4,7,8) |
| Sysbench                      | General system benchmark (deprecated)                        |
| Geekbench                     | Cross-platform benchmark suite (deprecated)                  |



## Prerequisites
The system must meet the following requirements:
| Requirement type        | Details                                                      | Mandatory |
| ----------------------- | ------------------------------------------------------------ | :-------: |
| Operating system💻       | Bash shell support                                           |     ✅     |
| Virtualization engine ⚙️ | Docker or Apptainer (formerly Singularity) installed         |     ✅     |
| Virtualization engine ⚙️ | Ability to execute the virtualization engine with `sudo` privileges |     ✅     |
| Filesystem access 📋     | `/proc/stat` must be available (CPU and system statistics)   |     ✅     |
| Filesystem access 📋     | `/sys/devices/system/cpu` must be available (CPU topology and information) |     ✅     |
| Filesystem access 📋     | `/sys/class/thermal` available (for temperature monitoring)  |     ❌     |
| MSR access 🗂️            | `/dev/cpu/[cpu_id]/msr` available (to read CPU voltage MSR)  |     ❌     |


## Quickstart

Clone this repository along with the required submodules:
```shell
git clone --recurse-submodules https://github.com/TomeMD/CPUPowerWatcher.git
```

Or update submodules if you have already cloned the repository:
```shell
git submodule update --init --recursive
```

Then, you can run CPUPowerWatcher just using `run.sh`.


## Options

````shell
~$ ./run.sh --help

Usage: run.sh [OPTIONS]
  -v, --os-virt             Technology for OS-level virtualization. [Default: apptainer]
                                docker
                                apptainer
  -i, --influxdb-host       InfluxDB host to send metrics. [Default: montoxo.des.udc.es]
  -b, --influxdb-bucket     InfluxDB bucket to store metrics. [Default: public]
  -o, --output <dir>        Directory (absolute path) to store log files. [Default: ./log]
  -w, --workload            Workload to stress the system with. [Default: stress-system]
                              npb                 Run NPB kenerls.
                              sysbench            Run Sysbench kernels.
                              geekbench           Run Geekbench kenerls.
                              fio                 Run fio to make random reads/writes over specified target with
                                                  different numbers of threads.
                                --fio-target      Directory to make random reads/writes. [Default: /tmp/fio]

                              spark               Run Spark-based DNA error correction algorithm (SMusket) using
                                                  Spark Standalone.
                                --spark-data-dir  Directory to store Spark temporary files and Spark Smusket input.
                                                  Input must be a FASTQ file named "input.fastq".

                              stress-system       Run stress tests using stress-system tool with different sets of
                                                  cores. Options:
                                --stressors              Comma-separated list of stressors to run with stress-system.
                                                         [Default: cpu]
                                --stress-time            Time (in seconds) under stress for each set of cores.
                                                         [Default: 120]
                                --stress-load-types      Comma-separated list of types of load to stress the CPU.
                                                         Used together with CPU stressor. [Default: all]
                                --stress-extra-options   Comma-separated list of other stress-ng options specified
                                                         in key=value format.

  --base                   Get base measurements before tests to have idle consumption and overhead metrics.
  --add-io-noise           Run fio to make random reads/writes over specified target while running the specified
                           workload. Use --fio-target to specify target directory. This option is not compatible with
                           fio tests.
  --custom-tests <file>    Use custom tests file to create custom lists of cores to stress.
                           [Default: ./bin/test/custom-tests.sh]
  -h, --help               Show this help and exit
````





