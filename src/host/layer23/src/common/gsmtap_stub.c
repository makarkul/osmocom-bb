/* Minimal stubs to satisfy linker when GSMTAP is disabled. */
#include <stdint.h>
#include <stdbool.h>

/* Provide minimal type compatibility */
struct gsmtap_hdr { uint8_t dummy; };
struct gsmtap_sink { int dummy; };
struct gsmtap_source { int dummy; };

int chantype_rsl2gsmtap2(uint8_t rsl_chantype, uint8_t link_id, bool sacch) { (void)rsl_chantype; (void)link_id; (void)sacch; return 0; }
const char * const * gsmtap_gsm_channel_names = 0;
struct gsmtap_source *gsmtap_source_init2(int a, const char *b, const char *c, const char *d, int e) { (void)a;(void)b;(void)c;(void)d;(void)e; return 0; }
int gsmtap_source_add_sink(struct gsmtap_source *s, struct gsmtap_sink *k) { (void)s; (void)k; return 0; }
int gsmtap_send_ex(struct gsmtap_source *s, uint16_t arfcn, int8_t signal_dbm, int8_t snr, uint8_t *frame, unsigned int frame_len, uint32_t frame_nr, int8_t tdma_timeslot, uint8_t channel_type, uint8_t sub_type, uint8_t antenna_nr, uint8_t sub_slot, uint16_t res, uint8_t payload_type) {
    (void)s;(void)arfcn;(void)signal_dbm;(void)snr;(void)frame;(void)frame_len;(void)frame_nr;(void)tdma_timeslot;(void)channel_type;(void)sub_type;(void)antenna_nr;(void)sub_slot;(void)res;(void)payload_type; return 0; }
int gsmtap_send(struct gsmtap_source *s, uint16_t arfcn, int8_t signal_dbm, int8_t snr, uint8_t chan_type, uint8_t ss, uint8_t timeslot, uint16_t frame_number, const uint8_t *data, uint16_t len) {
    (void)s;(void)arfcn;(void)signal_dbm;(void)snr;(void)chan_type;(void)ss;(void)timeslot;(void)frame_number;(void)data;(void)len; return 0; }
