#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "memtrack.h"

typedef struct AllocNode {
    void             *ptr;
    struct AllocNode *next;
} AllocNode;

static AllocNode *head_node = NULL;

static void track_add(void *p) {
    AllocNode *n = malloc(sizeof *n);
    if (!n) {
        perror("track_add"); exit(EXIT_FAILURE);
    }
    n->ptr = p;
    n->next = head_node;
    //printf("ADD NODE\t%p (node->ptr %p, node->next %p)\n", n, n->ptr,n->next);
    head_node = n;
}

static void track_remove(void *p) {
    AllocNode **node_ptr = &head_node; /* Get a pointer to the head node */
    while (*node_ptr) { /* The value pointed by node_ptr is the node (*node_ptr = node) */
        if ((*node_ptr)->ptr == p) {
            AllocNode *tofree = *node_ptr; /* Save current node to free */
            /* 'node_ptr' will be pointing to the head node (1st iteration) or to the 'next' field of the previous node.
               Then, we update the head node or the 'next' field of the previous node to the next node (skipping the
               current node) */
            *node_ptr = tofree->next;
            //printf("RMV NODE\t%p (node->ptr %p, node->next %p)\n", tofree, tofree->ptr,tofree->next);
            free(tofree);
            break;
        }
        node_ptr = &((*node_ptr)->next);
    }
}

void *tracked_malloc(size_t sz) {
    void *p = malloc(sz);
    if (p)
        track_add(p);
    return p;
}

void *tracked_calloc(size_t n, size_t sz) {
    void *p = calloc(n, sz);
    if (p)
        track_add(p);
    return p;
}

void *tracked_realloc(void *old, size_t new_sz) {
    if (!old)
        return tracked_malloc(new_sz);
    void *p = realloc(old, new_sz);
    if (p && p != old) {
        track_remove(old);
        track_add(p);
    }
    return p;
}

char *tracked_strdup(const char *s) {
    size_t len = strlen(s) + 1;
    char *p = tracked_malloc(len);
    if (p)
        memcpy(p, s, len);
    return p;
}

void tracked_free(void *p) {
    if (!p)
        return;
    track_remove(p);
    free(p);
    p = NULL;
}

static void cleanup_all(void) {
    AllocNode *node = head_node;
    while (node) {
        free(node->ptr); /* Free data pointer inside node */
        AllocNode *next = node->next; /* Get next node */
        free(node); /* Free current node */
        node = next; /* Update current node */
    }
    head_node = NULL;
}

__attribute__((constructor))
static void register_cleanup(void) {
    if (atexit(cleanup_all) != 0) {
        fprintf(stderr, "Failed to register cleanup_all\n");
        exit(EXIT_FAILURE);
    }
}
