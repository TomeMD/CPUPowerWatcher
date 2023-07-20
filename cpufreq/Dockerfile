FROM debian:bullseye-slim

RUN apt-get update && \
    apt-get install -y cpufrequtils curl

COPY cpufreq-influxdb.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/cpufreq-influxdb.sh

CMD ["/usr/local/bin/cpufreq-influxdb.sh"]
