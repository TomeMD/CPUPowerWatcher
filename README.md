# Stress-test-scripts

Set of scripts to automate CPU utilization and energy consumption monitoring while running stress tests. Options:

````shell
~$ ./run.sh --help

Usage: run.sh [OPTIONS]

Options:
  -d, --docker <0-or-1>    Set to 0 to use Docker or 1 to use Apptainer. [Default: 0]
  -n, --npb <T>            Set 0 for running NPB kenerls instead of running stress-tests [Default: 1]
  -g, --geekbench <T>      Set 0 for running Geekbench kenerls instead of running stress-tests [Default: 1]
  -o, --output <dir>       Directory to store log files. [Default: ./log]      
  -h, --help               Show this help and exit
````





