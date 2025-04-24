#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <time.h>
#include <limits.h>
#include <fcntl.h>
#include <dirent.h>
#include <stdarg.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "utils.h"


#if defined(_WIN32) || defined(_WIN64)
    #define PLATFORM_WINDOWS 1
#else
    #include <unistd.h>
    #define PLATFORM_UNIX 1
#endif

#define SYS_CPU_PATH "/sys/devices/system/cpu"
#define PROC_STAT_PATH "/proc/stat"


double vid_to_voltage(uint64_t msr_value) {
    uint64_t vid = (msr_value >> 32) & 0xFFFF;
    return (double) vid / 8192.0;
}

uint64_t get_ns_time() {
    struct timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    return (uint64_t)ts.tv_sec * 1000000000ULL + (uint64_t)ts.tv_nsec;
}

int max_int_array(int *arr, size_t size) {
    if (!arr || size == 0) {
        fprintf(stderr, "Error: null or empty array\n"); return -1;
    }
    int max = arr[0];
    size_t i;
    for (i = 1; i < size; i++) {
        if (arr[i] > max)
            max = arr[i];
    }
    return max;
}

ssize_t file_size(const char *filename) {
#ifdef PLATFORM_WINDOWS
    struct _stat st;
    if (_stat(filename, &st) == 0) {
        return (ssize_t) st.st_size;
    } else {
        perror("Error trying to get file size");
        return -1;
    }
#elif PLATFORM_UNIX
    struct stat st;
    if (stat(filename, &st) == 0) {
        return (ssize_t) st.st_size;
    } else {
        perror("Error trying to get file size");
        return -1;
    }
#else
    #error "Not supported platform"
#endif
}

int read_int_from_file(const char *path, int *value) {
    FILE *fp = fopen(path, "r");
    if (!fp) {
        perror("Error opening file"); return -1;
    }
    if (fscanf(fp, "%d", value) != 1) {
        perror("Error reading int from file"); fclose(fp); return -1;
    }
    fclose(fp); return 0;
}

int read_ull_from_file(const char *path, unsigned long long *value) {
    FILE *fp = fopen(path, "r");
    if (!fp) {
        perror("Error opening file"); return -1;
    }
    if (fscanf(fp, "%llu", value) != 1) {
        perror("Error reading ull from file"); fclose(fp); return -1;
    }
    fclose(fp); return 0;
}

int read_msr(int cpu, uint32_t msr_reg, uint64_t *value) {
    char msr_file_name[64];
    snprintf(msr_file_name, sizeof(msr_file_name), "/dev/cpu/%d/msr", cpu);
    int fd = open(msr_file_name, O_RDONLY);
    if (fd < 0) {
        perror("Error trying to open MSR file"); return -1;
    }
    if (pread(fd, value, sizeof(uint64_t), msr_reg) != sizeof(uint64_t)) {
        perror("Error trying to read MSR file"); close(fd); return -1;
    }
    close(fd);
    return 0;
}

int read_str_from_file(const char *filename, char *buffer, size_t bufsize) {
    FILE *fp = fopen(filename, "r");
    if (!fp) {
        perror("Error trying to open file");
        return -1;
    }
    /* Read (bufsize - 1) elements (length of file) to buffer */
    size_t read = fread(buffer, 1, bufsize - 1, fp);
    if ((read < bufsize - 1) && ferror(fp)) {
        perror("Error reading from file");
        fclose(fp); return -1;
    }
    buffer[read] = '\0';
    fclose(fp);
    /* Remove ending '\n' (UNIX) or '\r\n' (Windows) */
    while (read > 0 && (buffer[read-1] == '\n' || buffer[read-1] == '\r')) {
        buffer[--read] = '\0';
    }
    return 0;
}

void free_array(void **array, int count, void (*free_fn)(void *)) {
    if (!array) return;
    for (int i = 0; i < count; i++) {
        if (free_fn)
            free_fn(array[i]);
    }
    free(array);
}

int append_dynamic_array(void ***array, int *count, void *element) {
    void **tmp = realloc(*array, sizeof(void *) * (*count + 1));
    if (!tmp)
        return -1;
    *array = tmp;
    (*array)[*count] = element;
    (*count)++;
    return 0;
}

char *build_cpu_sysfs_path(const char *fmt, ...) {
    char suffix[PATH_MAX];
    char full_path[PATH_MAX];
    /* Save path suffix (e.g., "cpu%d/cpuidle/state%d/time") */
    va_list args;
    va_start(args, fmt);
    vsnprintf(suffix, sizeof(suffix), fmt, args); /* Replaces args in fmt (e.g., "cpu0/cpuidle/state0/time") */
    va_end(args);
    /* Save full path */
    int written = snprintf(full_path, sizeof(full_path), "%s/%s", SYS_CPU_PATH, suffix);
    if (written < 0 || written >= (int)sizeof(full_path))
        return NULL;
    /* Return a copy of the string on heap */
    return strdup(full_path);
}

char **read_cstate_names(const char *dir_path, int *cstate_count) {
    DIR *d = opendir(dir_path);
    if (!d) {
        perror("Error: Unable to open C-states directory"); return NULL;
    }

    char **cstate_names = NULL;
    char buf[64];
    struct dirent *entry;
    *cstate_count = 0;
    while ((entry = readdir(d))) {
        if (strncmp(entry->d_name, "state", 5) != 0)
            continue;
        /* Read name from C-states file (e.g., /sys/devices/system/cpu/cpu0/cpuidle/state0/name) */
        char *cpath = build_cpu_sysfs_path("cpu%d/cpuidle/%s/name", 0, entry->d_name);
        if (read_str_from_file(cpath, buf, sizeof(buf)) != 0) {
            perror("Error reading C-States name file");
            closedir(d); return NULL;
        }
        free(cpath);
        /* Append name to array */
        char *buf_copy = strdup(buf);
        if (append_dynamic_array((void ***)&cstate_names, cstate_count, buf_copy) != 0) {
            perror("Error appending element to C-State names array");
            closedir(d); return NULL;
        }
    }
    closedir(d);
    return cstate_names;
}

void split_stat_line(const char *line, unsigned long long *out, size_t max) {
    char *copy = strdup(line);
    char *tok = strtok(copy, " ");
    int idx = 0;
    /* line format: <cpuX> <user> <nice> <system> <idle> <iowait> <irq> <softirq> ... */
    while (tok && idx < (int)max) {
        if (idx > 0) /* CPU tag is ignored */
            out[idx] = strtoull(tok, NULL, 10);
        tok = strtok(NULL, " ");
        idx++;
    }
    free(copy);
}

int read_proc_stats(int max_core, char ***out_lines, int *out_count) {
    FILE *fp = fopen(PROC_STAT_PATH, "r");
    if (!fp) {
        perror("Error opening/proc/stat"); return -1;
    }

    int needed_lines = max_core + 2;  /* line global CPU + lines cpu0..cpuN */
    char **lines = malloc(needed_lines * sizeof(char*));
    if (!lines) {
        perror("Error allocating space for /proc/stat lines array");
        fclose(fp); return -1;
    }

    const int bufsize = 1024;
    char buf[bufsize];
    int idx = 0;
    while (idx < needed_lines && fgets(buf, bufsize, fp)) {
        lines[idx] = strndup(buf, bufsize);
        if (!lines[idx]) {
            perror("Error allocating space for line in /proc/stat");
            for (int j = 0; j < idx; j++)
                free(lines[j]);
            free(lines); fclose(fp); return -1;
        }
        idx++;
    }

    fclose(fp);
    *out_lines  = lines;
    *out_count  = idx;
    return 0;
}