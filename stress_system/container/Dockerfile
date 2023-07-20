# Base image
FROM debian:bullseye-slim

# Copy files
COPY . /usr/local/bin/stress-system/

# Install stress-ng and set run.sh as executable
RUN apt-get update && apt-get install -y stress-ng && \
    chmod +x /usr/local/bin/stress-system/run.sh && \
    mkdir /tmp/out

# Runscript and Startscript are combined into an ENTRYPOINT and CMD for Docker
ENTRYPOINT ["/usr/local/bin/stress-system/run.sh"]
