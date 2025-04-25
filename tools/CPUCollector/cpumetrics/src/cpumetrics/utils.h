#ifndef UTILS_H
#define UTILS_H

#include <stddef.h>
#include <stdint.h>
#include <sys/types.h>

/**
 * Convert a raw MSR (Model-Specific Register) value into a voltage.
 *
 * @param msr_value  The 64-bit value read from the MSR.
 * @return           Voltage in volts (e.g., 1.200 means 1.2V).
 */
double vid_to_voltage(uint64_t msr_value);

/**
 * Convert a 64-bit unsigned integer (uint64_t) to a string.
 *
 * @param buf       Buffer to store the output string (must be pre-allocated).
 * @param value     64-bit unsigned integer value.
 * @return          0 on success, -1 on error.
 */
int uint64_to_str(char *buf, uint64_t value);

/**
 * Get the current time in nanoseconds since the Epoch.
 * @return  Current time in nanoseconds.
 */
uint64_t get_ns_time(void);

/**
 * Find the maximum value in an array of integers.
 *
 * @param arr   Pointer to the first element of the array.
 * @param size  Number of elements in the array.
 * @return      The maximum value in the array, or -1 on error (null or empty array).
 */
int max_int_array(int *arr, size_t size);

/**
 * Get the size of a file in bytes.
 *
 * @param filename  Path to the file.
 * @return          File size in bytes on success, or -1 on error.
 */
ssize_t file_size(const char *filename);

/**
 * Read an integer from a text file.
 *
 * @param path   Path to the text file.
 * @param value  Pointer to an int to receive the value.
 * @return       0 on success, -1 on error.
 */
int read_int_from_file(const char *path, int *value);

/**
 * Read an unsigned long long from a text file.
 *
 * @param path   Path to the text file.
 * @param value  Pointer to unsigned long long to receive the value.
 * @return       0 on success, -1 on error.
 */
int read_ull_from_file(const char *path, unsigned long long *value);


/**
 * Reads a 64-bit MSR register from a given core ID.
 *
 * @param cpu       Core ID (e.g., 0 for first core).
 * @param msr_reg   The MSR register number to read (e.g., 0x198 for MSR_PERF_STATUS).
 * @param value     Pointer to store the 64-bit result.
 * @return          0 on success, -1 on error.
 */
int read_msr(int cpu, uint32_t msr_reg, uint64_t *value);

/**
 * Read a string from a text file into a buffer, trimming trailing newline '\n' and/or carriage return '\r'.
 *
 * @param filename  Path to the text file.
 * @param buffer    Destination buffer (must be pre-allocated).
 * @param bufsize   Size of the buffer in bytes.
 * @return          0 on success, -1 on error.
 */
int read_str_from_file(const char *filename, char *buffer, size_t bufsize);

/**
 * Free an array of pointers and then free the array itself.
 *
 * @param array     Pointer to the first element of the array (allocated via tracked_realloc).
 * @param count     Number of elements in the array.
 * @param free_fn   Function to free each element (e.g., tracked_free).
 */
void free_array(void **array, int count, void (*free_fn)(void *));

/**
 * Append an element to a dynamically-sized array, resizing with tracked_realloc.
 *
 * @param array    Pointer to the array pointer (void***). On success, *array is updated to the new buffer.
 * @param count    Pointer to the current element count; incremented on success.
 * @param element  Pointer to the new element to append.
 * @return         0 on success, -1 on allocation error.
 */
int append_dynamic_array(void ***array, int *count, void *element);

/**
 * Build a sysfs path for CPU-related data using printf-style formatting. Format: '<SYS_CPU_PATH>/<fmt>'
 *
 * @param fmt  printf-style format string for the suffix (e.g., "cpu%d/cpuidle/state%d/time").
 * @param ...  Arguments to replace in the format string.
 * @return     Newly-allocated string with the full path or NULL on truncation.
 *             Caller must free the new allocated memory.
 */
char *build_cpu_sysfs_path(const char *fmt, ...);

/**
 * Try to read the names of existing C-States from the specified directory.
 *
 * @param dir_path       Path to the directory (e.g., "/sys/devices/system/cpu/cpu0/cpuidle").
 * @param cstate_count   Output pointer to save the number of C-States found.
 * @return               Array of newly-allocated C-State name strings or NULL on error.
 *                       Caller must free the new allocated array.
 */
char **read_cstate_names(const char *dir_path, int *cstate_count);

/**
 * Split a "/proc/stat" CPU line into numeric fields. Expected line format is:
 *
 *      <cpuX> <user> <nice> <system> <idle> <iowait> <irq> <softirq> ...
 *
 * @param line  A string containing one line from "/proc/stat".
 * @param out   Pre-allocated array of unsigned long long[<max>] to receive fields. out[1] = user, out[2] = nice,...
 * @param max   Maximum number of fields to read from line and save in out.
 */
void split_stat_line(const char *line, unsigned long long *out, size_t max);

/**
 * Read core_max+2 lines from /proc/stat (global line + lines cpu0..cpuN)
 *
 * @param max_core     Índice máximo de CPU (N).
 * @param out_lines    Pointer to a char** buffer (not pre-allocated). Caller must free this array outside.
 * @param out_count    Pointer to save number of lines read.
 * @return             0 on success, -1 on error.
 */
int read_proc_stats(int max_core, char ***out_lines, int *out_count);

#endif /* UTILS_H */