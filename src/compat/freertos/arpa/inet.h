/*
 * arpa/inet.h compatibility header for FreeRTOS
 * Provides IP address conversion functions
 */

#ifndef FREERTOS_ARPA_INET_H
#define FREERTOS_ARPA_INET_H

#include <stddef.h>  /* For NULL */
#include "../netinet/in.h"

/* Make sure INET6_ADDRSTRLEN is visible */
#ifndef INET6_ADDRSTRLEN
#define INET6_ADDRSTRLEN 46
#endif

/* Stub implementations for IP address conversion */
/* These return error codes since full implementation requires more complex parsing */

static inline int inet_pton(int af, const char *src, void *dst) {
    /* Stub implementation - not supported in minimal FreeRTOS build */
    (void)af; (void)src; (void)dst;
    return 0; /* Error - not supported */
}

static inline const char *inet_ntop(int af, const void *src, char *dst, uint32_t size) {
    /* Stub implementation - not supported in minimal FreeRTOS build */
    (void)af; (void)src; (void)dst; (void)size;
    return NULL; /* Error - not supported */
}

static inline uint32_t inet_addr(const char *cp) {
    /* Stub implementation - not supported in minimal FreeRTOS build */
    (void)cp;
    return 0xFFFFFFFF; /* INADDR_NONE */
}

#endif /* FREERTOS_ARPA_INET_H */