#pragma once
#ifdef DISABLE_GSMTAP
#include <stdint.h>
#include <stdbool.h>
struct gsmtap_header_dummy { uint8_t d; };
int chantype_rsl2gsmtap2(uint8_t rsl_chantype, uint8_t link_id, bool sacch);
#endif
