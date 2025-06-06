export LOG_DIR="${GLOBAL_HOME}"/log
export OS_VIRT="apptainer"
export WORKLOAD="stress-system"
export STRESSORS="cpu"
export CORE_DISTRIBUTIONS="all"
export FINAL_CORE_DISTRIBUTIONS=()
export STRESS_PATTERN="stairs-up"
export STRESS_TIME=120
export IDLE_TIME=20
export LOAD_TYPES="all"
export STRESS_EXTRA_OPTS=""
export STRESS_EXTRA_OPTS_ARRAY=()
export INFLUXDB_HOST="montoxo.des.udc.es"
export INFLUXDB_BUCKET="public"
export GEEKBENCH_VERSION="5.4.1"
export SPARK_VERSION="3.3.3"
export GET_BASE_MEASUREMENTS=0
export ADD_IO_NOISE=0
export FIO_TARGET=/tmp/fio
export SPARK_DATA_DIR="${GLOBAL_HOME}"/data
export CUSTOM_TESTS=0
export CUSTOM_TESTS_FILE="${GLOBAL_HOME}"/bin/test/custom-tests.sh