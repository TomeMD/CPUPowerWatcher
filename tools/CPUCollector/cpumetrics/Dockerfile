FROM debian:bookworm-slim AS builder

# Set environment variables
ENV CPUMETRICS_SRC=/var/lib/cpumetrics

# Install basic packages
RUN apt-get update && apt-get install -y --no-install-recommends build-essential

# Copy cpumetrics source code
COPY ./src/cpumetrics ${CPUMETRICS_SRC}

# Compile cpumetrics tool
RUN cd "${CPUMETRICS_SRC}" && \
    make clean && \
    make LDFLAGS="-static -s"

# The final image is Alpine in order to have lscpu support
FROM alpine:3.21

# Add lscpu and name resolution for the static binary
RUN apk add --no-cache lscpu && \
    echo "hosts: files dns" > /etc/nsswitch.conf
    
COPY --from=builder /var/lib/cpumetrics/cpumetrics /usr/local/bin/cpumetrics

# Run cpumetrics
ENTRYPOINT ["/usr/local/bin/cpumetrics"]