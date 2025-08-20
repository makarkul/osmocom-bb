/*
 * netinet/in.h compatibility header for FreeRTOS
 * Provides network address structures and functions
 */

#ifndef FREERTOS_NETINET_IN_H
#define FREERTOS_NETINET_IN_H

#include "../sys/socket.h"
#include <stdint.h>

/* IPv4 address structure */
struct in_addr {
    uint32_t s_addr;
};

/* IPv6 address structure */
struct in6_addr {
    uint8_t s6_addr[16];
};

/* Address string length constants */
#define INET_ADDRSTRLEN  16
#define INET6_ADDRSTRLEN 46

/* IPv6 socket options */
#define IPV6_TCLASS 67

/* Multicast structures */
struct ip_mreq {
    struct in_addr imr_multiaddr;
    struct in_addr imr_interface;  
};

struct ip_mreqn {
    struct in_addr imr_multiaddr;
    struct in_addr imr_address;
    int imr_ifindex;
};

/* Port conversion functions - simple stub implementations */
static inline uint16_t htons(uint16_t hostshort) {
    return ((hostshort & 0xff) << 8) | ((hostshort >> 8) & 0xff);
}

static inline uint16_t ntohs(uint16_t netshort) {
    return ((netshort & 0xff) << 8) | ((netshort >> 8) & 0xff);
}

static inline uint32_t htonl(uint32_t hostlong) {
    return ((hostlong & 0x000000ff) << 24) | 
           ((hostlong & 0x0000ff00) << 8)  |
           ((hostlong & 0x00ff0000) >> 8)  |
           ((hostlong & 0xff000000) >> 24);
}

static inline uint32_t ntohl(uint32_t netlong) {
    return ((netlong & 0x000000ff) << 24) | 
           ((netlong & 0x0000ff00) << 8)  |
           ((netlong & 0x00ff0000) >> 8)  |
           ((netlong & 0xff000000) >> 24);
}

#endif /* FREERTOS_NETINET_IN_H */