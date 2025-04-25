FROM debian:bullseye-slim

# Set environment variables
ENV CPUMETRICS_SRC=/var/lib/cpumetrics

# Install basic packages
RUN apt-get update && apt-get install -y msr-tools build-essential gcc git

# Copy cpumetrics source code
COPY --chown=0 ./src/cpumetrics ${CPUMETRICS_SRC}

# Compile cpumetrics
RUN cd "${CPUMETRICS_SRC}" && \
    make && \
    chmod +x "${CPUMETRICS_SRC}/cpumetrics" && \
    mv "${CPUMETRICS_SRC}/cpumetrics" /usr/local/bin/cpumetrics

# Run cpumetrics
ENTRYPOINT ["/usr/local/bin/cpumetrics"]