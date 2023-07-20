# stress-system

A tool to load and stress a multicore architectures using `stress-ng`.

- [Running stress-system](#run-stress-system)
- [Options](#options)
  - [Stressing CPU](#stressing-cpu)
  - [Stressing other components](#stressing-other-components)

<a name="run-stress-system"></a>
## Running stress-system

You can run this tool in the following three ways:

- [Local](#local)
- [Using Docker containers](#docker)
- [Using Apptainer containers](#apptainer)

<a name="local"></a>

### Local

To run this tool on your physical machine all you need is to have `stress-ng` installed. To install `stress-ng` follow the instructions in its [official repository](https://github.com/ColinIanKing/stress-ng).

Once `stress-ng` is installed run the tool with:

```shell
./run.sh
```

<a name="docker"></a>

### Using Docker containers

First, you need to build the docker image:

```dockerfile
docker build -t stress-system -f container/Dockerfile .
```

Then you can run the tool:

```dockerfile
docker run -ti [-v <host-dir>:<container-dir>] stress-system [-o <container-dir> <other-options>]
```

To store the logs on your physical machine you have to mount a volume from host to container and specify the container directory as the output parameter of the tool (-o option). Here is an example in which the logs are stored in the `/tmp` directory of the container, which we can access through the `./out` directory from our machine:

```dockerfile
docker run -ti -v $(pwd)/out:/tmp stress-system -o /tmp -l 100 -c 0,6,7 
```

To run the container in background:

```dockerfile
docker run -d [-v <host-dir>:<container-dir>] stress-system [-o <container-dir> <other-options>]
```

<a name="apptainer"></a>

### Using Apptainer containers

First you need to build Apptainer image (SIF file):

```shell
cd container && apptainer build stress.sif stress.def && cd ..
```

Logs will be written to the `/tmp/out/report_$(date '+%d_%m_%Y_%H-%M-%M-%S')` directory, as Apptainer shares this directory with the host by default. Therefore, do not modify the tool's output directory. Now run the image in foreground:

```shell
apptainer run container/stress.sif [<options-except-output>]
```

Or in the background:

```shell
sudo apptainer instance start container/stress.sif [<options-except-output>]
```
<a name="options"></a>
## Options

You can specify the options from the CLI or by modifying the `./experiment/stress-conf.sh` configuration file. 

```shell
# ./run.sh --help
Usage: run.sh [OPTIONS]

Options:
  -i, --iterations <I>    Run tests I times. [Default: 1]
  -b, --time-btw-iters <T>    Wait T seconds between iterations. [Default: 10s]
  -t, --timeout <T>       Stop tests after T seconds. Time units can be specified by using suffixes. [Default: 10s]
  				s = seconds
  				m = minutes
  				h = hours
  				d = days
  				y = years
  -s, --stressors []      Comma-separated list of stressors to run on system. [Default: cpu]
  -l, --cpu-load <P>      Stress CPU with P percent of CPU load. The load will be assigned to cores incrementally. Used together with CPU stressor. [Default: 50%]
                          Example: "run.sh -l 130 -c 3,6" will load core 3 at 100% and core 6 at 30%.
  --cpu-load-types []     Comma-separated list of types of load to stress the CPU. Used together with CPU stressor. [Default: all]
  -c, --cores-list []     Comma-separated list of cores on which you want to run the tests [Default: all]
  -o, --output <dir>      Directory to store log files. [Default: ./out]      
  -h, --help              Show this help and exit

Example of use:
  run.sh --timeout 10s --stressors cpu --cpu-load 230 --cpu-load-types double,int64 --cores-list 0,2,4
```
<a name="stress-cpu"></a>
### Stressing CPU

This tool assigns the load incrementally to each core, instead of distributing the load among all available cores. To better understand his behavior see the examples below.

#### Example 1

```shell
run.sh --timeout 10s --stressors cpu --cpu-load 70 --cpu-load-types double --cores-list 0,2,4
```
| Core | Load |
| :--: | :--: |
|  0   | 70%  |
|  2   |  0%  |
|  4   |  0%  |


It will load core 0 with 70% of load using double tests for 10 seconds. It will ignore cores 2 and 4 as there is not enough load for them.


#### Example 2

```shell
run.sh -i 3 --timeout 1m --stressors cpu --cpu-load 140 --cpu-load-types all --cores-list 0,2,4
```
| Core | Load |
| :--: | :--: |
|  0   | 100% |
|  2   | 40%  |
|  4   |  0%  |


It will load core 0 with 100% of load and core 2 with 40% of load using all tests for 1 minute 3 times. It will ignore core 4 as there is not enough load for it.


#### Example 3

```shell
run.sh --timeout 1m --stressors cpu --cpu-load 240 --cpu-load-types all --cores-list 0,2,4
```
| Core | Load |
| :--: | :--: |
|  0   | 100% |
|  2   | 100% |
|  4   | 40%  |


It will load core 0 and 2 with 100% of load and core 4 with 40% of load using all tests for 1 minute.


#### Example 4

```shell
run.sh --timeout 1m --stressors cpu --cpu-load 340 --cpu-load-types all --cores-list 0,2,4
```
| Core | Load |
| :--: | :--: |
|  0   | 100% |
|  2   | 100% |
|  4   | 100% |


It will load core 0, 2 and 4 with 100% of load using all tests for 1 minute. Although specified load is 340%, the maximum load that can be executed with 3 cores is 300%, so the load value is reassigned to its maximum possible value (300%).

<a name="stress-other-components"></a>
### Stressing other components

When using any stressor but *cpu* it's not possible to specify a particular CPU load. Actually, you can set a CPU load, however, probably the actual load will be diferent from the desired load.

#### Example

```shell
run.sh --timeout 10s --stressors cpu,iomix --cpu-load 150 
```
| Core | Desired Load | Actual Load |
| :--: | :--: | :--: |
|  0   | 100% | 89%  |
|  2   | 50%  | 35%  |
|  4   |  0%  |  0%  |


While cpu stressor will try to load core 0 with 100% of load and core 1 with 50% of it, iomix stressor will be competing with cpu stressor for the same resources without taking into account any specific load.