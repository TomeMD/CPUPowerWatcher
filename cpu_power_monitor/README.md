# Glances + CPUfreq + RAPL + InfluxDB +  Grafana
Deployment of a container-based solution for monitoring power consumption and CPU load and frequency. Based on your preferences, you can deploy containers using  [Docker](#docker) or using [Apptainer](#apptainer).

<a name="docker"></a>

## Docker deployment

You can deploy Docker containers in the following two ways:

- [Manual deployment](#manual): Running Docker commands.
- [Automatic deployment](#auto): Running Docker-Compose.

---
<a name="manual"></a>

### Manual Deployment
First the images must be created and then the containers must be executed.

#### Building images
To begin with, it will be necessary to create the network that allows InfluxDB and Grafana containers to communicate

```shell
docker network create -d bridge --opt com.docker.network.bridge.name=br_grafana grafana_network
```

And create an image for the containers for which it is necessary (Glances, CPUfreq, RAPL and InfluxDB):

```shell
docker build -t glances ./glances
```

```shell
docker build -t cpufreq ./cpufreq
```

```shell
docker build -t rapl ./rapl
```

```shell
docker build -t myinfluxdb ./influxdb
```

#### Containers deployment

After creating the images, the containers are started in an ordered way.

First, deploy InfluxDB:

```shell
docker run -d --name influxdb -p 8086:8086 --restart=unless-stopped \
					-e "DOCKER_INFLUXDB_INIT_MODE=setup" \
					-e "DOCKER_INFLUXDB_INIT_USERNAME=admin" \
					-e "DOCKER_INFLUXDB_INIT_PASSWORD=12345678" \
					-e "DOCKER_INFLUXDB_INIT_ORG=MyOrg" \
					-e "DOCKER_INFLUXDB_INIT_BUCKET=glances" \
					-e "DOCKER_INFLUXDB_INIT_RETENTION=4w" \
					-e "DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=MyToken" \
					-e "DOCKER_INFLUXDB_INIT_CLI_CONFIG_NAME=MyConfig" \
					-v ./influxdb/data:/var/lib/influxdb2 \
					-v ./influxdb/etc:/etc/influxdb2 \
					--network grafana_network myinfluxdb
```

Now deploy Grafana, you must replace `<uid>:<gid>` by your UID and GID (on most systems you should be able to get them by running `id -u` and `id -g`):

```shell
docker run -d --name grafana -p 8080:3000 --restart=unless-stopped -u <uid>:<gid> -v ./grafana/data:/var/lib/grafana -v ./grafana/provisioning/datasources:/etc/grafana/provisioning/datasources --network grafana_network grafana/grafana
```

Finally, deploy Glances, CPUfreq and RAPL containers:

```shell
docker run -d --name glances --pid host --privileged --network host --restart=unless-stopped -e GLANCES_OPT="-q --export influxdb2 --time 2" glances
```

```shell
docker run -d --name cpufreq --pid host --privileged --network host --restart=unless-stopped cpufreq
```

```shell
docker run -d --name rapl --pid host --privileged --network host --restart=unless-stopped rapl
```

Once deployed, if you want to stop the containers:

```shell
docker stop rapl
docker stop cpufreq
docker stop glances
docker stop grafana
docker stop influxdb
```

Once stopped, if you want to remove the containers permanently:

```shell
docker rm rapl
docker rm cpufreq
docker rm glances
docker rm grafana
docker rm influxdb
```

---
<a name="auto"></a>
## Automatic Deployment

First of all you must introduce your UID and GID in the .env file. Then you can deploy the containers by simply executing:

```shell
docker-compose up -d
```

To stop the containers:

```shell
docker-compose stop
```

To stop and remove the containers:

```shell
docker-compose down
```

<a name="apptainer"></a>
## Apptainer Deployment

The deployment of containers using Apptainer will be done manually.

---
<a name="manual"></a>

### Manual Deployment
First, you have to create the images and then you should create instances to run the containers in the background.

#### Building images
Initially it will be necessary to create an image (.sif file) for the containers for which it is necessary (Glances, CPUfreq, RAPL and InfluxDB). When using Apptainer you have to care about the directory from which you build the images:

```shell
cd glances && apptainer build glances.sif glances.def && cd ..
```

```shell
cd cpufreq && apptainer build cpufreq.sif cpufreq.def && cd ..
```

```shell
cd rapl && apptainer build rapl.sif rapl.def && cd ..
```

```shell
cd influxdb && apptainer build influxdb.sif influxdb.def && cd ..
```
#### Instances deployment

As well as in Docker, instances must be started in an ordered way. First, deploy InfluxDB:

```shell
apptainer instance start --env-file influxdb/env/influxdb.env --bind ./influxdb/data:/var/lib/influxdb2 --bind ./influxdb/etc:/etc/influxdb2 influxdb/influxdb.sif influxdb
```

Now deploy Grafana:

```shell
apptainer instance start --bind ./grafana/data:/var/lib/grafana --bind ./grafana/provisioning/datasources:/etc/grafana/provisioning/datasources docker://grafana/grafana grafana
```

Finally, deploy Glances, CPUfreq and RAPL containers:
```shell
apptainer instance start --env "GLANCES_OPT=-q --export influxdb2 --time 2" glances/glances.sif glances
```

```shell
apptainer instance start ${CPUFREQ_HOME}/cpufreq.sif cpufreq
```

```shell
apptainer instance start rapl/rapl.sif rapl
```

Once deployed, if you want to stop and remove the instances:

```shell
apptainer instance stop rapl
apptainer instance stop cpufreq
apptainer instance stop glances
apptainer instance stop grafana
apptainer instance stop influxdb
```