/*
Usage: ./monitor <CORES_LIST> <INFLUXDB_HOST> <INFLUXDB_BUCKET>
*/
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <limits.h>
#include <dirent.h>
#include <signal.h>
#include "utils.h"
#include "influxdb-client/ic.h"

#define MAX_CORES 256
#define MONITOR_TEMPERATURE 1
#define MONITOR_VOLTAGE 0
#define MONITOR_CSTATES 0
#define SEPARATE_MULTITHREADING_USAGE 1

/* sysfs paths */
#define SYS_CPU_PATH    "/sys/devices/system/cpu"
#define SYS_TEMP_PATH   "/sys/class/thermal"
#define MSR_PERF_STATUS 0x198

void signal_handler(int sig) {
    const char *sig_name = strsignal(sig);
    fprintf(stderr, "\nSignal received: %s (%d)\n", sig_name ? sig_name : "UNKNOWN", sig);
    exit(EXIT_FAILURE);
}

void setup_signal_handlers() {
    struct sigaction sa;
    sa.sa_handler = signal_handler;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = 0;
    sigaction(SIGINT,  &sa, NULL);  /* Ctrl-C */
    sigaction(SIGTERM, &sa, NULL);  /* kill */
    sigaction(SIGHUP,  &sa, NULL);  /* Close terminal */
    sigaction(SIGQUIT, &sa, NULL);  /* Ctrl-\ */
}

int main(int argc, char **argv) {
    char cores_str[1024];
    char influxdb_host[100];
    char influxdb_bucket[100];
    const int sampling_frequency_us = 1e6;

    if(argc != 4) {
         fprintf(stderr, "Error: Missing some arguments\n");
         fprintf(stderr, "Usage: %s <CORES_LIST> <INFLUXDB_HOST> <INFLUXDB_BUCKET>\n", argv[0]);
         exit(EXIT_FAILURE);
    }

    /* Set signal handlers to manage not normal terminations */
    setup_signal_handlers();

    /* Read arguments */
    if (sscanf(argv[1], "%1023s", cores_str) != 1) {
        fprintf(stderr, "Error: Bad <CORES_LIST> argument: %s\n", argv[1]); exit(EXIT_FAILURE);
    }
    if (sscanf(argv[2], "%99s", influxdb_host) != 1) {
        fprintf(stderr, "Error: Bad <INFLUXDB_HOST> argument: %s\n", argv[1]); exit(EXIT_FAILURE);
    }
    if (sscanf(argv[3], "%99s", influxdb_bucket) != 1) {
        fprintf(stderr, "Error: Bad <INFLUXDB_BUCKET> argument: %s\n", argv[1]); exit(EXIT_FAILURE);
    }

    /* Get list of cores from the input string (e.g. '0,1,2,3' -> [0,1,2,3]) */
    int cores[MAX_CORES];
    int num_cores = 0;
    for (char *tok = strtok(cores_str, ","); tok && num_cores < MAX_CORES; tok = strtok(NULL, ",")) {
        cores[num_cores++] = atoi(tok);
    }
    if (num_cores == 0) {
        fprintf(stderr, "No cores specified (empty list)\n"); exit(EXIT_FAILURE);
    }

    /* Get the higher core number from the list */
    int max_core;
    if ((max_core = max_int_array(cores, num_cores)) == -1) {
        fprintf(stderr, "Error: unable to get the higher core number\n"); exit(EXIT_FAILURE);
    }

    /* Check sysfs is accesible to retrieve information */
    if(access(SYS_CPU_PATH, R_OK) != 0) {
        fprintf(stderr, "Error: No read access to CPU info from sysfs: %s\n", SYS_CPU_PATH); exit(EXIT_FAILURE);
    }

    // *********************************************************************
    // InfluxDB initialization
    // *********************************************************************
    ic_debug(0);
    ic_influx_database(influxdb_host, 8086, influxdb_bucket, "MyOrg", "MyToken"); /* Create InfluxDB Client */

    // *********************************************************************
    // Temperature initialization
    // *********************************************************************
    if(MONITOR_TEMPERATURE && access(SYS_TEMP_PATH, R_OK) != 0) {
        fprintf(stderr, "Error: No read access to temperature info from sysfs: %s\n", SYS_TEMP_PATH); exit(EXIT_FAILURE);
    }

    // *********************************************************************
    // C-States initialization
    // *********************************************************************
    int num_cstates = 0;
    char **cstate_names = NULL;
    unsigned long long **prev_cstate_times = NULL;
    unsigned long long *prev_cstate_total = NULL;
    if (MONITOR_CSTATES) {
        /* Get CPU0 C-States directory to look for the available C-States on this CPU */
        char cpu0_cstates_dir_path[100];
        snprintf(cpu0_cstates_dir_path, sizeof(cpu0_cstates_dir_path), "%s/cpu0/cpuidle", SYS_CPU_PATH);

        /* Get C-State names */
        if (!(cstate_names = read_cstate_names(cpu0_cstates_dir_path, &num_cstates))) {
            fprintf(stderr, "Error getting C-State names from directory: %s\n", cpu0_cstates_dir_path); exit(EXIT_FAILURE);
        }

        /* Initialise arrays to store the previous value of each state on each core along with an array
           to store the total values per core (sum of all states) */
        prev_cstate_times = calloc(max_core+1, sizeof(*prev_cstate_times));
        prev_cstate_total = calloc(max_core+1, sizeof(unsigned long long));
        for (int c = 0; c <= max_core; c++) {
            prev_cstate_times[c] = calloc(num_cstates, sizeof(unsigned long long));
            prev_cstate_total[c] = 0ULL;
        }
    }

    // *********************************************************************
    // CPU usage initialization
    // *********************************************************************
    /* Allocate arrays indexed by core to store previous time value. Some memory will be wasted if all the cores
       are not used but this waste is limited by the maximum number of cores in a machine */
    unsigned long long *prev_user   = calloc(max_core+1, sizeof(unsigned long long));
    unsigned long long *prev_system = calloc(max_core+1, sizeof(unsigned long long));
    unsigned long long *prev_iowait = calloc(max_core+1, sizeof(unsigned long long));
    unsigned long long *prev_total  = calloc(max_core+1, sizeof(unsigned long long));
    if (!prev_user || !prev_system || !prev_iowait || !prev_total ) {
        fprintf(stderr, "Error: Allocating memory to store CPU previous values\n"); exit(EXIT_FAILURE);
    }

    // *********************************************************************
    // Physical/Logical cores map initialization
    // *********************************************************************
    int *log_phy_mapping = NULL;
    if(SEPARATE_MULTITHREADING_USAGE > 0) {
        log_phy_mapping = calloc(max_core+1, sizeof(int));
        int *core_found = calloc(max_core+1, sizeof(int));
        int cpu, core;
        /* Run lscpu to get physical/logical cores mapping */
        FILE *fp = popen("lscpu -e | awk 'NR > 1 { print $1, $4 }'", "r");
        if(!fp) {
            perror("Error running lscpu to get cores physical/logical cores mapping"); exit(EXIT_FAILURE);
        }
        /* If we find a second CPU in the same core we mark it as a logical core */
        while(fscanf(fp, "%d %d", &cpu, &core) == 2) {
            if(core >= 0 && core <= max_core && cpu <= max_core) {
                if(core_found[core] == 0) {
                    log_phy_mapping[cpu] = 1; core_found[core] = 1; // Physical core (1)
                } else {
                    log_phy_mapping[cpu] = 0; // Logical core (0)
                }
            }
        }
        pclose(fp);
        free(core_found);
    }

    // *********************************************************************
    // Main loop
    // *********************************************************************
    uint64_t start_monitoring, end_monitoring, end_timestamp, end_epoch;
    double sleep_time_us, total_delay_us, monitoring_delay_us, epoch_time_us;
    unsigned long long *cstate_core_times = calloc(num_cstates, sizeof(unsigned long long));
    char start_timestamp_str[32];
    char **proc_lines = NULL;
    int proc_count = 0;
    printf("Start measuring loop...\n");
    while(1) {

        /* Get start time in nanoseconds */
        start_monitoring = get_ns_time();
        if (uint64_to_str(start_timestamp_str, start_monitoring) != 0) {
            fprintf(stderr, "Error during conversion of start timestamp to string\n"); exit(EXIT_FAILURE);
        }

        // Cumulative variables for global CPU metrics
        unsigned long long total_freq = 0;
        unsigned long long sum_user = 0, sum_sys = 0, sum_iowait = 0;
        unsigned long long pl_user[2]={0,0}, pl_sys[2]={0,0};

        /* Read information about CPU usage time from /proc/stat file */
        if (read_proc_stats(max_core, &proc_lines, &proc_count) != 0 || proc_count < max_core + 2) {
            fprintf(stderr, "Error getting CPU information from /proc/stat\n"); exit(EXIT_FAILURE);
        }

        /* Compute per-core information */
        for(int i = 0; i < num_cores; i++) {
            int core = cores[i];

            /* Add InfluxDB subtag for core metrics */
            char core_tag[32];
            snprintf(core_tag, sizeof(core_tag), "core=%d", core);
            ic_tags(core_tag); /* Add InfluxDB tag for global data */
            ic_measure("cpu_metrics"); /* Initialise measurement for core data */

            // -----------------------------------------------------------------
            // Frequency
            // -----------------------------------------------------------------
            char *freq_path = build_cpu_sysfs_path("cpu%d/cpufreq/scaling_cur_freq", core);
            unsigned long long freq_core = 0;
            if (!freq_path) {
                fprintf(stderr, "Error creating frequency sysfs path for core %d\n", core); exit(EXIT_FAILURE);
            }
            if (read_ull_from_file(freq_path, &freq_core) != 0) {
                fprintf(stderr, "Error reading frequency from %s\n", freq_path); exit(EXIT_FAILURE);
            }
            free(freq_path);

            // -----------------------------------------------------------------
            // CPU usage
            // -----------------------------------------------------------------
            unsigned long long cpu_times[10] = {0};
            unsigned long long total = 0;
            /* Get CPU times from /proc/stat line CPU+1 (first line is whole CPU) */
            split_stat_line(proc_lines[core+1], cpu_times, 10);
            for (int j = 1; j < 10; j++)
                total += cpu_times[j];

            /* Total CPU elapsed time */
            unsigned long long elapsed_time = total - prev_total[core];

            /* Delta for each type of usage: user, system and iowait */
            unsigned long long du = cpu_times[1] - prev_user[core];
            unsigned long long ds = cpu_times[3] - prev_system[core];
            unsigned long long di = cpu_times[5] - prev_iowait[core];

            /* Proportional delta over total elapsed time */
            unsigned long long u_pct = elapsed_time ? (100*du/elapsed_time):0;
            unsigned long long s_pct = elapsed_time ? (100*ds/elapsed_time):0;
            unsigned long long i_pct = elapsed_time ? (100*di/elapsed_time):0;

            /* Save values for next iteration */
            prev_total[core] = total; prev_user[core] = cpu_times[1]; prev_system[core] = cpu_times[3]; prev_iowait[core] = cpu_times[5];

            /* Add core metrics to cumulative variables (whole CPU) */
            total_freq += freq_core; sum_user += u_pct; sum_sys += s_pct; sum_iowait += i_pct;

            /* Separate user and system usage between physical and logical cores */
            if (SEPARATE_MULTITHREADING_USAGE) {
                int idx=log_phy_mapping[core];
                pl_user[idx]+=u_pct;
                pl_sys[idx]+=s_pct;
            }

            /* Save InfluxDB fields with core usage and frequency info */
            ic_double("freq", (double) freq_core);
            ic_double("user", (double) u_pct);
            ic_double("system", (double) s_pct);
            ic_double("iowait", (double) i_pct);

            // -----------------------------------------------------------------
            // C-States
            // -----------------------------------------------------------------
            if (MONITOR_CSTATES) {
                /* Read time for all available C-States */
                total = 0;
                for (int s = 0; s < num_cstates; s++) {
                    unsigned long long value;
                    char *cpath = build_cpu_sysfs_path("cpu%d/cpuidle/state%d/time", core, s);
                    if (read_ull_from_file(cpath, &value) == 0) {
                        cstate_core_times[s] = value; total += value;
                    } else {
                        fprintf(stderr, "Failed to read value from %s\n", cpath); cstate_core_times[s] = 0;
                    }
                    free(cpath);
                }
                /* Get total elapsed time for C-States */
                elapsed_time = total - prev_cstate_total[core];

                /* Compute proportional delta for each C-State */
                unsigned long long dstate, pct;
                for (int s = 0; s < num_cstates; s++) {
                    dstate = cstate_core_times[s] - prev_cstate_times[core][s]; /* Get delta for C-State */
                    pct = elapsed_time ? (100*dstate/elapsed_time):0; /* Proportional delta over total elapsed time */
                    prev_cstate_times[core][s] = cstate_core_times[s];
                    ic_double(cstate_names[s], (double) pct);
                }

                prev_cstate_total[core] = total;
            }

            // -----------------------------------------------------------------
            // Voltage
            // -----------------------------------------------------------------
            if (MONITOR_VOLTAGE) {
                uint64_t msr;
                if (read_msr(core, MSR_PERF_STATUS, &msr) != 0) {
                    fprintf(stderr, "Error getting MSR value for core %d\n", core); exit(EXIT_FAILURE);
                }
                double v = vid_to_voltage(msr);
                ic_double("vcore", v);
            }
            ic_measureend(start_timestamp_str); /* End InfluxDB measurement */
        }

        // ---------------------------------------------------------------------
        // Global data
        // ---------------------------------------------------------------------
        ic_tags("core=all"); /* Add InfluxDB tag for global data */
        ic_measure("cpu_metrics"); /* Initialise measurement for global data */

        /* Add global metrics */
        unsigned long long avg_freq = num_cores ? (total_freq/num_cores/1000):0;
        ic_double("avgfreq", (double) avg_freq);
        ic_double("sumfreq", (double) total_freq);
        ic_double("user", (double) sum_user);
        ic_double("system", (double) sum_sys);
        ic_double("iowait", (double) sum_iowait);
        if (SEPARATE_MULTITHREADING_USAGE) {
            ic_double("puser", (double) pl_user[1]);
            ic_double("luser", (double) pl_user[0]);
            ic_double("psystem", (double) pl_sys[1]);
            ic_double("lsystem", (double) pl_sys[0]);
        }

        if (MONITOR_TEMPERATURE) {
            DIR *td = opendir(SYS_TEMP_PATH);
            struct dirent *entry;
            while (td && (entry = readdir(td))) {
                if (strncmp(entry->d_name, "thermal_zone", 12) == 0) {
                    char tpath[PATH_MAX], field_name[64];
                    int tv; double temp_value;
                    char *zone_num = entry->d_name + strlen("thermal_zone");
                    /* Read file with temperature info (e.g., /sys/class/thermal/thermal_zone0/temp) */
                    snprintf(tpath, sizeof(tpath), "%s/%s/temp", SYS_TEMP_PATH, entry->d_name);
                    read_int_from_file(tpath, &tv);
                    temp_value = tv / 1000; /* Set temperature in ºC */
                    /* Set field name for temperature depending on thermal zone*/
                    snprintf(field_name, sizeof(field_name), "temp%s", zone_num);
                    ic_double(field_name, temp_value);
                }
            }
            if (td)
                closedir(td);
        }

        free_array((void**) proc_lines, proc_count, free);
        ic_measureend(start_timestamp_str); /* End InfluxDB measurement */

        end_monitoring = get_ns_time();

        ic_push(); /* Send data to InfluxDB */

        end_timestamp = get_ns_time();

        //printf("user = %lld\tsystem=%lld\tiowait=%lld\n", sum_user, sum_sys, sum_iowait);

        monitoring_delay_us = (end_monitoring - start_monitoring) / 1e3;
        total_delay_us = (end_timestamp - start_monitoring) / 1e3;
        sleep_time_us = (sampling_frequency_us > total_delay_us) ? (sampling_frequency_us-total_delay_us):0;

        /*printf("Monitoring delay:   %10.3f\n", monitoring_delay_us);
          printf("InfluxDB delay:     %10.3f\n", total_delay_us - monitoring_delay_us);
          printf("Total delay:        %10.3f\n", total_delay_us);
          printf("Sleep time:         %10.3f\n", sleep_time_us);*/

        usleep(sleep_time_us);

        end_epoch = get_ns_time();
        epoch_time_us = (end_epoch - start_monitoring) / 1e3;

        //printf("Epoch time: %10.3f microseconds\n", epoch_time_us);
    }

    exit(EXIT_SUCCESS);
}
