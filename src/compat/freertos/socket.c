/*
 * FreeRTOS Socket Compatibility Layer Implementation
 * 
 * Implements POSIX socket compatibility functions using FreeRTOS+TCP
 */

#include "socket.h"

#ifdef TARGET_FREERTOS

#include <string.h>
#include <stdio.h>

/* Include network database header for struct addrinfo */
#include <netdb.h>

/* Include required headers for memory management */
#if FREERTOS_HEADERS_AVAILABLE && defined(FREERTOS_RUNTIME)
  #include "task.h"  
#else
  #include <stdlib.h>
#endif

/* Initialize socket compatibility layer */
int freertos_socket_compat_init(void)
{
#if FREERTOS_HEADERS_AVAILABLE && defined(FREERTOS_RUNTIME)
    /* FreeRTOS+TCP initialization would go here if needed */
    return 0;
#else
    /* No initialization needed for stub mode */
    return 0;
#endif
}

/* Basic select() implementation for FreeRTOS */
int freertos_select(int nfds, fd_set *readfds, fd_set *writefds, fd_set *exceptfds, struct timeval *timeout)
{
#if FREERTOS_HEADERS_AVAILABLE && defined(FREERTOS_RUNTIME)
    /* FreeRTOS+TCP has FreeRTOS_select() but API may differ */
    /* For now, provide a basic stub that doesn't block */
    (void)nfds; (void)readfds; (void)writefds; (void)exceptfds; (void)timeout;
    return 0; /* No sockets ready */
#else
    /* Stub implementation */
    (void)nfds; (void)readfds; (void)writefds; (void)exceptfds; (void)timeout;
    return 0;
#endif
}

/* Basic getaddrinfo() implementation for FreeRTOS */
int freertos_getaddrinfo(const char *node, const char *service, const struct addrinfo *hints, struct addrinfo **res)
{
#if FREERTOS_HEADERS_AVAILABLE && defined(FREERTOS_RUNTIME)
    /* FreeRTOS+TCP has FreeRTOS_getaddrinfo() */
    (void)node; (void)service; (void)hints;
    
    /* Provide minimal stub - allocate result structure */
    struct addrinfo *result = (struct addrinfo*)pvPortMalloc(sizeof(struct addrinfo));
    if (!result) return -1;
    
    memset(result, 0, sizeof(struct addrinfo));
    result->ai_family = AF_INET;
    result->ai_socktype = SOCK_STREAM;
    
    *res = result;
    return 0;
#else
    /* Stub implementation */
    (void)node; (void)service; (void)hints;
    *res = NULL;
    return -1; /* Not implemented */
#endif
}

/* Free getaddrinfo() results */
void freertos_freeaddrinfo(struct addrinfo *res)
{
    if (res) {
#if FREERTOS_HEADERS_AVAILABLE && defined(FREERTOS_RUNTIME)
        vPortFree(res);
#else
        free(res);
#endif
    }
}

#endif /* TARGET_FREERTOS */