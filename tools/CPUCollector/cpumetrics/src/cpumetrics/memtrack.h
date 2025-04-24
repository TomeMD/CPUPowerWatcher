#ifndef MEMTRACK_H
#define MEMTRACK_H

#include <stddef.h>

/**
 * Allocate a block of memory and register it for automatic cleanup.
 *
 * @param sz  Number of bytes to allocate.
 * @return    Pointer to the allocated memory, or NULL if allocation fails.
 */
void *tracked_malloc(size_t sz);

/**
 * Allocate and zero-initialize an array, registering it for automatic cleanup.
 *
 * @param n   Number of elements.
 * @param sz  Size of each element, in bytes.
 * @return    Pointer to the allocated memory, or NULL if allocation fails.
 */
void *tracked_calloc(size_t n, size_t sz);

/**
 * Resize a previously allocated block (or allocate if NULL), updating the tracker.
 *
 * If realloc moves the block, the old pointer is removed from the tracker
 * and the new pointer is registered.
 *
 * @param old     Previously allocated pointer. If NULL only a tracked_malloc is done.
 * @param new_sz  New size in bytes.
 * @return        Pointer to the resized block, or NULL if allocation fails (old remains valid).
 */
void *tracked_realloc(void *old, size_t new_sz);

/**
 * Duplicate a string via tracked_malloc, registering the copy for automatic cleanup.
 *
 * @param s  Null-terminated source string.
 * @return   Newly allocated copy of s, or NULL on allocation failure.
 */
char *tracked_strdup(const char *s);

/**
 * Free a tracked block immediately and remove it from the tracker.
 *
 * @param p  Pointer previously returned by one of the tracked_... allocators.
 */
void tracked_free(void *p);

#endif /* MEMTRACK_H */
