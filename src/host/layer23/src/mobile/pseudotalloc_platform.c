#include <stdlib.h>
#include <stddef.h>
void *pseudotalloc_malloc(size_t size) { return malloc(size ? size : 1); }
void pseudotalloc_free(void *ptr) { free(ptr); }
