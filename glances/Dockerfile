FROM nicolargo/glances:latest-full
COPY etc/glances.conf /etc/glances.conf
CMD /venv/bin/python3 -m glances -C /etc/glances.conf $GLANCES_OPT