/*
MIT License

Copyright (c) 2014-2023 Universidade da Coruña

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "papi.h"
#include "influxdb-client/ic.h"

#define MAX_EVENTS 32

int lld_to_str(char *buf, long long value) {
    size_t len = 21; /* 20 digits + '/0' */
    int ret;
    if (!buf) {
        fprintf(stderr, "Error: Converting long long to str: buf empty or too small (<%ld)\n", len); return -1;
    }
    if ((ret = snprintf(buf, len, "%lld", value)) < 0) {
        fprintf(stderr, "Error: snprintf encoding failed\n"); return -1;
    }
    return 0;
}

int main (int argc, char **argv) {
    const int minimum_interval = 1e4; /* microseconds (0.01 seconds) */
    int retval,cid,rapl_cid=-1,numcmp;
    int i,code,enum_retval,seconds_interval,microseconds_interval,max_time;
    int num_events = 0;
    int EventSet = PAPI_NULL;
    long long values[MAX_EVENTS];
    char influxdb_host[100] = "montoxo.des.udc.es";
    char influxdb_bucket[100] = "public";
    char hostname[1024], host_tag[1024+5];
    char event_name[BUFSIZ];
    PAPI_event_info_t evinfo;
    const PAPI_component_info_t *cmpinfo = NULL;
    long long start_time,before_time,after_time,offset_time,sleep_time;
    double elapsed_time,total_time;
    char events[MAX_EVENTS][BUFSIZ];
    char units[MAX_EVENTS][BUFSIZ];

    seconds_interval = 1;
    max_time = 0;
    if (argc > 1) {
        if (argc == 2) {
        sscanf(argv[1], "%s", influxdb_host);
        } else if (argc == 3) {
        sscanf(argv[1], "%s", influxdb_host);
        sscanf(argv[2], "%s", influxdb_bucket);
        } else if (argc == 4) {
        sscanf(argv[1], "%s", influxdb_host);
        sscanf(argv[2], "%s", influxdb_bucket);
        sscanf(argv[3], "%i", &seconds_interval);
        } else if (argc == 5) {
        sscanf(argv[1], "%s", influxdb_host);
        sscanf(argv[2], "%s", influxdb_bucket);
        sscanf(argv[3], "%i", &seconds_interval);
        sscanf(argv[4], "%i", &max_time);
        } else {
        fprintf(stderr, "Usage: %s [INFLUXDB_HOST INFLUXDB_BUCKET INTERVAL_SECONDS MAX_TIME_SECONDS]\n", argv[0]);
        exit(-1);
        }
    }

    microseconds_interval = seconds_interval * 1e6;
    printf("Interval: %i s (%i us)\n", seconds_interval, microseconds_interval);
    printf("Max time: %i s\n", max_time);

    /* PAPI Initialization */
    retval = PAPI_library_init( PAPI_VER_CURRENT );
    if ( retval != PAPI_VER_CURRENT ) {
        fprintf(stderr, "PAPI_library_init failed\n");
        exit(-1);
    }

    numcmp = PAPI_num_components();

    for (cid=0; cid<numcmp; cid++) {
		if ((cmpinfo = PAPI_get_component_info(cid)) == NULL) {
			fprintf(stderr,"PAPI_get_component_info failed\n");
			exit(1);
		}

		if (strstr(cmpinfo->name, "rapl")) {
			rapl_cid=cid;
			printf("Found RAPL component at cid %d\n", rapl_cid);

			if (cmpinfo->disabled) {
				fprintf(stderr, "RAPL component disabled: %s\n", cmpinfo->disabled_reason);
				exit(-1);
			}
			break;
		}
    }

    /* Component not found */
    if (cid == numcmp) {
        fprintf(stderr, "Error! No RAPL component found!\n");
        exit(1);
    }

    /* Find Events */
    code = PAPI_NATIVE_MASK;
    enum_retval = PAPI_enum_cmp_event(&code, PAPI_ENUM_FIRST, cid);
    while (enum_retval == PAPI_OK) {
        retval = PAPI_event_code_to_name(code, event_name);
        if (retval != PAPI_OK) {
            fprintf(stderr, "Error translating %#x\n", code);
            exit(-1);
	    }

        printf("Found event: %s\n", event_name);

        if (strstr(event_name, "ENERGY") != NULL && strstr(event_name, "ENERGY_CNT") == NULL) {
            strncpy(events[num_events], event_name, BUFSIZ);

            /* Find additional event information: unit, data type */
            retval = PAPI_get_event_info(code, &evinfo);
            if (retval != PAPI_OK) {
                fprintf(stderr, "Error getting event info for %#x\n", code);
                exit(-1);
            }

            strncpy(units[num_events], evinfo.units, sizeof(units[0])-1);
            /* buffer must be null terminated to safely use strstr operation on it below */
            units[num_events][sizeof(units[0])-1] = '\0';

            num_events++;

            if (num_events == MAX_EVENTS) {
                fprintf(stderr, "Too many events! %d\n", num_events);
                exit(-1);
            }
        }

        enum_retval = PAPI_enum_cmp_event(&code, PAPI_ENUM_EVENTS, cid);
    }

    if (num_events == 0) {
    	fprintf(stderr, "Error! No RAPL events found!\n");
        exit(-1);
    }

    /* Create EventSet */
    retval = PAPI_create_eventset(&EventSet);
    if (retval != PAPI_OK) {
        fprintf(stderr, "Error creating EventSet\n");
        exit(-1);
    }

    for (i=0; i<num_events; i++) {
        printf("Saved event: %s\n", events[i]);
        retval = PAPI_add_named_event(EventSet, events[i]);
        if (retval != PAPI_OK) {
            fprintf(stderr, "Error adding event %s\n", events[i]);
                exit(-1);
        }
    }

    retval = gethostname(hostname, sizeof(hostname));
    if (retval != 0) {
        fprintf(stderr, "Error getting hostname\n");
        exit(-1);
    }
    snprintf(host_tag, sizeof(host_tag), "host=%s", hostname);

    // Create InfluxDB Client
    ic_debug(0);
    ic_influx_database(influxdb_host, 8086, influxdb_bucket, "MyOrg", "MyToken");
    ic_tags(host_tag);

    printf("Starting measuring loop...\n");
    fflush(stdout);
    fflush(stderr);

    double energy, power;
    double energy_pp0_pkg0 = 0, power_pp0_pkg0 = 0, energy_pp0_pkg1 = 0, power_pp0_pkg1 = 0;
    double energy_pkg0 = 0, power_pkg0 = 0, energy_pkg1 = 0, power_pkg1 = 0;
    int events_to_send;
    char column_joules[40], column_watts[40], measure_energy[40], measure_power[40], influxdb_timestamp[32];
    start_time=PAPI_get_real_nsec();
    after_time=start_time;

    /* Main loop */
    while (1) {

        /* Start counting */
        before_time=PAPI_get_real_nsec();
        retval = PAPI_start(EventSet);
        if (retval != PAPI_OK) {
            fprintf(stderr, "PAPI_start() failed\n");
            exit(-1);
        }

        offset_time=(PAPI_get_real_nsec() - after_time)/1000 + 50;
        sleep_time=(offset_time < microseconds_interval) ? (microseconds_interval - offset_time):minimum_interval;

        usleep(sleep_time);

        /* Stop counting */
        after_time=PAPI_get_real_nsec();
        retval = PAPI_stop(EventSet, values);
        if (retval != PAPI_OK) {
            fprintf(stderr, "PAPI_stop() failed\n");
            exit(-1);
        }

        total_time=((double)(after_time-start_time))/1.0e9;
        elapsed_time=((double)(after_time-before_time))/1.0e9;

        if (lld_to_str(influxdb_timestamp, after_time) != 0) {
            fprintf(stderr, "Error during conversion of after time to string (InfluxDB timestamp)\n"); exit(EXIT_FAILURE);
        }

        energy_pkg0 = 0;
        energy_pkg1 = 0;
        energy_pp0_pkg0 = 0;
        energy_pp0_pkg1 = 0;
        events_to_send = 0;
        for (i=0; i<num_events; i++) {

            /* Energy consumption is returned in nano-Joules (nJ) */
            energy = ((double)values[i] / 1.0e9);
            power = energy / elapsed_time;

            strcpy(column_joules, events[i]);
            strcat(column_joules, "(J)");
            strcpy(column_watts, events[i]);
            strcat(column_watts, "(W)");

            //printf("events[%i]=%s, values[%i]=%lli\n", i, events[i], i, values[i]);
            //printf("Energy %.3f, Power %.3f\n", energy, power);

            if (energy == 0)
                continue;

            if (strstr(events[i], "DRAM_")) {
                strcpy(measure_energy, "ENERGY_DRAM");
                strcpy(measure_power, "POWER_DRAM");
            } else if (strstr(events[i], "PP0_")) {
                strcpy(measure_energy, "ENERGY_PP0");
                strcpy(measure_power, "POWER_PP0");
                if (strstr(events[i], "PACKAGE0")) {
                    energy_pp0_pkg0 = energy;
                    power_pp0_pkg0 = power;
                } else if (strstr(events[i], "PACKAGE1")) {
                    energy_pp0_pkg1 = energy;
                    power_pp0_pkg1 = power;
                }
            } else if (strstr(events[i], "PP1_")) {
                strcpy(measure_energy, "ENERGY_PP1");
                strcpy(measure_power, "POWER_PP1");
            } else if (strstr(events[i], "PSYS_")) {
                strcpy(measure_energy, "ENERGY_PSYS");
                strcpy(measure_power, "POWER_PSYS");
            } else if (strstr(events[i], "PACKAGE_")) {
                strcpy(measure_energy, "ENERGY_PACKAGE");
                strcpy(measure_power, "POWER_PACKAGE");
                if (strstr(events[i], "PACKAGE0")) {
                    energy_pkg0 = energy;
                    power_pkg0 = power;
                } else if (strstr(events[i], "PACKAGE1")) {
                    energy_pkg1 = energy;
                    power_pkg1 = power;
                }
            } else {
                fprintf(stderr, "Error! Unexpected event %s found!\n", events[i]);
            }

            ic_measure(measure_energy);
            ic_double(column_joules, energy);
            ic_measureend(influxdb_timestamp);
            ic_measure(measure_power);
            ic_double(column_watts, power);
            ic_measureend(influxdb_timestamp);

            events_to_send += 1;
	    }

        if (energy_pp0_pkg0 != 0) {
            //printf("energy_pkg0 %.3f, energy_pp0_pkg0 %.3f\n", energy_pkg0, energy_pp0_pkg0);
            ic_measure("UNCORE_ENERGY_PACKAGE");
            ic_double("UNCORE_ENERGY:PACKAGE0(J)", energy_pkg0 - energy_pp0_pkg0);
            ic_measureend(influxdb_timestamp);

            ic_measure("UNCORE_POWER_PACKAGE");
            ic_double("UNCORE_POWER:PACKAGE0(W)", power_pkg0 - power_pp0_pkg0);
            ic_measureend(influxdb_timestamp);

            events_to_send += 1;
        }

        if (energy_pp0_pkg1 != 0) {
            //printf("energy_pkg1 %.3f, energy_pp0_pkg1 %.3f\n", energy_pkg1, energy_pp0_pkg1);
            ic_measure("UNCORE_ENERGY_PACKAGE");
            ic_double("UNCORE_ENERGY:PACKAGE1(J)", energy_pkg1 - energy_pp0_pkg1);
            ic_measureend(influxdb_timestamp);

            ic_measure("UNCORE_POWER_PACKAGE");
            ic_double("UNCORE_POWER:PACKAGE1(W)", power_pkg1 - power_pp0_pkg1);
            ic_measureend(influxdb_timestamp);

            events_to_send += 1;
        }

        if (events_to_send)
            ic_push(); // Send metrics to InfluxDB

        if (max_time > 0 && total_time >= max_time)
            break;
    }

    printf("Finished loop. Total running time: %.4f s\n", total_time);    
    exit(0);
}