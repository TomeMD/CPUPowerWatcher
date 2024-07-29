FROM nicolargo/glances:latest-full
COPY etc/glances.conf /etc/glances/glances.conf
COPY start-glances.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/start-glances.sh"]