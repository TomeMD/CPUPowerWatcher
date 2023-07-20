# Stress-test-scripts

Set of scripts to automate CPU utilization, frequency and energy consumption monitoring while running stress tests. Options:

````shell
~$ ./run.sh --help

Usage: run.sh [OPTIONS]

Options:
  -d, --docker             Use Docker for OS-level virtualization. [Default]
  -a, --apptainer          Use Apptainer for OS-level virtualization.
  -s, -stress-tests        Run stress tests using stress-system tool. [Default]
  -n, --npb                Run NPB kenerls.
  -g, --geekbench          Run Geekbench kenerls.
  -o, --output <dir>       Directory to store log files. [Default: ./log]      
  -h, --help               Show this help and exit
````





