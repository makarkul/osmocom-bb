/*
 * Minimal stub implementations to build without GPRS, talloc, gsmtap.
 * This is a temporary placeholder to allow FreeRTOS-focused build.
 */
#include <stdint.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stddef.h>

/* ---- talloc stub subset ---- */
void *talloc_named_const(const void *ctx, size_t size, const char *name) { return 0; }
void *talloc_named(const void *ctx, size_t size, const char *fmt, ...) { return 0; }
void *talloc_zero(const void *ctx, size_t size) { return 0; }
int talloc_free(void *ptr) { return 0; }
void *talloc_size(const void *ctx, size_t size) { return 0; }
char *talloc_strdup(const void *t, const char *p) { return 0; }
char *talloc_strndup(const void *t, const char *p, size_t n) { return 0; }
char *talloc_asprintf_append(char *s, const char *fmt, ...) { return s; }
char *talloc_strdup_append_buffer(char *s, const char *a) { return s; }
char *talloc_strndup_append_buffer(char *s, const char *a, size_t n) { return s; }
const char *talloc_get_name(const void *ptr) { return "stub"; }
int talloc_total_blocks(const void *ptr) { return 0; }
int talloc_reference_count(const void *ptr) { return 0; }
void talloc_report_depth_cb(const void *root, int depth, void (*cb)(const void *, int, int, size_t, void *), void *private_data) {}
int talloc_set_name(const void *ptr, const char *fmt, ...) { return 0; }
int talloc_set_destructor(const void *ptr, int (*destructor)(void *)) { return 0; }

/* ---- gsmtap stubs ---- */
int gsmtap_source_init(const char *host, uint16_t port, int ofd, int *gsmtap_fd) { return 0; }
int gsmtap_source_add_sink(int src, const char *path) { return 0; }
int gsmtap_send(void *gsmtap_inst, uint16_t arfcn, uint8_t timeslot, uint8_t sub_slot, uint8_t signal_dbm, uint8_t snr, uint8_t frame_type, uint32_t frame_number, const uint8_t *data, unsigned int len) { return 0; }
int gsmtap_send_ex(void *gi, uint16_t arfcn, uint8_t timeslot, uint8_t sub_slot, uint8_t signal_dbm, uint8_t snr, uint8_t frame_type, uint32_t fn, const uint8_t *data, unsigned int len, uint8_t channel_type_1, uint8_t channel_type_2, uint8_t sub_type, uint8_t antenna_nr, uint8_t sub_slot2, uint32_t frame_number_2) { return 0; }
const char * const *gsmtap_gsm_channel_names = 0;
int log_target_create_gsmtap(void *ctx, const char *host, uint16_t port) { return 0; }

/* ---- other logging / misc stubs referencing talloc append helpers ---- */
/* Additional placeholders if code expects pseudotalloc_* symbols */
void *pseudotalloc_malloc(size_t s) { (void)s; return 0; }
void pseudotalloc_free(void *p) { (void)p; }

/* Provide distinct implementations (avoid duplicate symbol) */
char *talloc_asprintf_append_buffer(char *s, const char *fmt, ...) { (void)fmt; return s; }
void talloc_report_depth_cb(const void *root, int depth, void (*cb)(const void *, int, int, size_t, void *), void *private_data)
{ (void)root; (void)depth; (void)cb; (void)private_data; }

/* Ensure no unused translation unit warnings by referencing at least one symbol */
static int _stubs_no_gprs_keep;
