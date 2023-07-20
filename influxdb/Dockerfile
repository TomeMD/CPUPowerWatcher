FROM influxdb:latest

RUN apt-get update && \
	apt-get install -y python3-pip && \
	pip3 install influxdb-client

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["influxd"]
