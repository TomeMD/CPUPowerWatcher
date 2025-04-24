CC       = gcc
CFLAGS   = -O2 -Wall -Wextra
LDFLAGS  =
LDLIBS   =
TARGET   = cpumetrics

OBJS     = cpumetrics.o utils.o ic.o

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(LDFLAGS) -o $(TARGET) $(OBJS) $(LDLIBS)

# Compile cpumetrics
cpumetrics.o: cpumetrics.c utils.h influxdb-client/ic.h
	$(CC) $(CFLAGS) -c -o $@ $<

# Compile utils module
utils.o: utils.c utils.h
	$(CC) $(CFLAGS) -c -o $@ $<

# Compile InfluxDB client
ic.o: influxdb-client/ic.c influxdb-client/ic.h
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -f $(OBJS) $(TARGET)
