/*
 * sys/socket.h compatibility header for FreeRTOS
 * Provides basic socket types and structures
 */

#ifndef FREERTOS_SYS_SOCKET_H
#define FREERTOS_SYS_SOCKET_H

#include <stdint.h>

/* Forward declaration - multicast structures moved to netinet/in.h */
struct in_addr;

/* Always define basic socket structures for libosmocore compatibility */

/* Socket length type */
typedef uint32_t socklen_t;

/* Address families */
#define AF_INET     2
#define AF_INET6    10
#define AF_UNSPEC   0

/* Socket types */
#define SOCK_STREAM 1
#define SOCK_DGRAM  2

/* Protocol numbers */
#define IPPROTO_IP   0
#define IPPROTO_TCP  6
#define IPPROTO_UDP  17
#define IPPROTO_IPV6 41

/* Basic socket address structure */
struct sockaddr {
    uint16_t sa_family;
    char sa_data[14];
};

/* IPv4 socket address */
struct sockaddr_in {
    uint16_t sin_family;
    uint16_t sin_port;
    struct {
        uint32_t s_addr;
    } sin_addr;
    char sin_zero[8];
};

/* IPv6 socket address */
struct sockaddr_in6 {
    uint16_t sin6_family;
    uint16_t sin6_port;
    uint32_t sin6_flowinfo;
    struct {
        uint8_t s6_addr[16];
    } sin6_addr;
    uint32_t sin6_scope_id;
};

/* Generic socket address storage - make sure it's visible */
#ifndef _SOCKADDR_STORAGE_DEFINED
#define _SOCKADDR_STORAGE_DEFINED
struct sockaddr_storage {
    uint16_t ss_family;
    char __data[126];
};
#endif

/* Socket level constants */
#define SOL_SOCKET   1

/* Socket options */
#define SO_PRIORITY  12
#define IP_MULTICAST_IF 32
#define IP_TOS 1

/* FD set for select() - minimal implementation */
/* Only define if compiling for actual FreeRTOS target */
#ifdef FREERTOS_RUNTIME
#ifndef FD_SETSIZE
#define FD_SETSIZE 64
typedef struct {
    uint64_t fds_bits;
} fd_set;

struct timeval {
    long tv_sec;
    long tv_usec;
};

#define FD_ZERO(set) ((set)->fds_bits = 0)
#define FD_SET(fd, set) ((set)->fds_bits |= (1ULL << (fd)))
#define FD_CLR(fd, set) ((set)->fds_bits &= ~(1ULL << (fd)))
#define FD_ISSET(fd, set) (((set)->fds_bits & (1ULL << (fd))) != 0)
#endif /* FD_SETSIZE */
#endif /* FREERTOS_RUNTIME */

/* Stub socket functions */
static inline int setsockopt(int sockfd, int level, int optname, const void *optval, uint32_t optlen) {
    /* Stub implementation - not supported in FreeRTOS build */
    (void)sockfd; (void)level; (void)optname; (void)optval; (void)optlen;
    return 0; /* Success */
}

static inline int getsockopt(int sockfd, int level, int optname, void *optval, uint32_t *optlen) {
    /* Stub implementation - not supported in FreeRTOS build */
    (void)sockfd; (void)level; (void)optname; (void)optval; (void)optlen;
    return 0; /* Success */
}

#endif /* FREERTOS_SYS_SOCKET_H */