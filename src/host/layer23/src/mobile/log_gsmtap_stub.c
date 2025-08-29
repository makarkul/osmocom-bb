#include <stdint.h>
#include <stdbool.h>
#include <osmocom/core/logging.h>
#ifdef DISABLE_GSMTAP
struct log_target *log_target_create_gsmtap(const char *host, uint16_t port,
                                            const char *name, bool ofd_wq_mode,
                                            bool add_hierarchy) {
    (void)host; (void)port; (void)name; (void)ofd_wq_mode; (void)add_hierarchy; return NULL; }
#endif
