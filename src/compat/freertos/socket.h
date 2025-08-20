/*
 * socket.h compatibility header for FreeRTOS
 * Provides socket functionality for embedded builds
 */

#ifndef FREERTOS_SOCKET_H
#define FREERTOS_SOCKET_H

#ifdef TARGET_FREERTOS

/* Check if FreeRTOS+TCP headers are available at build time */
#if defined(__has_include)
  #if __has_include("FreeRTOS_IP.h") && __has_include("FreeRTOS_Sockets.h")
    #define FREERTOS_HEADERS_AVAILABLE 1
  #else
    #define FREERTOS_HEADERS_AVAILABLE 0
  #endif
#else
  #define FREERTOS_HEADERS_AVAILABLE 0
#endif

#include <stdint.h>
#include <stddef.h>

/* Include our socket structures that libosmocore needs */
#include <sys/socket.h>

/* Socket compatibility layer function declarations */
int freertos_socket_compat_init(void);

/* Only provide FreeRTOS mappings if building for actual FreeRTOS runtime */
#if FREERTOS_HEADERS_AVAILABLE && defined(FREERTOS_RUNTIME)
  #include "FreeRTOS.h"
  #include "FreeRTOS_IP.h" 
  #include "FreeRTOS_Sockets.h"
  
  /* Map POSIX socket functions to FreeRTOS equivalents where needed */
  #define inet_addr(cp) FreeRTOS_inet_addr(cp)
  #define htons(hostshort) FreeRTOS_htons(hostshort)
  #define ntohs(netshort) FreeRTOS_ntohs(netshort)
  #define htonl(hostlong) FreeRTOS_htonl(hostlong)  
  #define ntohl(netlong) FreeRTOS_ntohl(netlong)
#endif

#endif /* TARGET_FREERTOS */

#endif /* FREERTOS_SOCKET_H */