FROM debian:bookworm-slim AS builder

ENV PAPI_VERSION=7.2.0
ENV RAPL_HOME=/var/lib/rapl
ENV PAPI_HOME=${RAPL_HOME}/papi-${PAPI_VERSION}
ENV RAPL_SRC=/var/lib/rapl/rapl_plot

RUN apt-get update && apt-get install -y --no-install-recommends build-essential

# Copy PAPI source code
COPY ./src/papi-${PAPI_VERSION} ${PAPI_HOME}

# Compile PAPI
RUN cd ${PAPI_HOME}/src && \
  chmod +x configure && \
  ./configure --with-components="rapl" && \
  make

# Compile RAPL tool
COPY ./src/rapl_plot ${RAPL_SRC}
RUN cd ${RAPL_SRC} && \
  rm -f rapl_plot rapl_plot.o && \
  make CC="gcc -static -s"

FROM busybox:1.37

COPY --from=builder /var/lib/rapl/rapl_plot/rapl_plot /usr/local/bin/rapl_plot

# Name resolution of the static binary
RUN echo "hosts: files dns" > /etc/nsswitch.conf

# Execute rapl_plot
ENTRYPOINT ["/usr/local/bin/rapl_plot"]
