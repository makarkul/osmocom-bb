/* Expanded talloc compatibility layer for pseudotalloc usage.
 * Only compiled when real talloc (libtalloc) is not available or when
 * ENABLE_PSEUDOTALLOC is defined by configure (--enable-freertos path).
 */
#include <stdarg.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#if defined(ENABLE_PSEUDOTALLOC) || defined(ENABLE_FREERTOS) || defined(TARGET_FREERTOS)
int talloc_set_name(const void *ptr, const char *fmt, ...) { (void)ptr; (void)fmt; return 0; }
int talloc_set_destructor(const void *ptr, int (*destructor)(void *)) { (void)ptr; (void)destructor; return 0; }
char *talloc_strndup(const void *ctx, const char *p, size_t n) { (void)ctx; if (!p) return NULL; size_t l = strnlen(p,n); char *s = malloc(l+1); if (!s) return NULL; memcpy(s,p,l); s[l]='\0'; return s; }

static char *dup_cat(char *orig, const char *suffix)
{
    if (!suffix)
        return orig;

    if (!orig) {
        size_t ls = strlen(suffix);
        char *n = malloc(ls + 1);
        if (!n)
            return NULL;
        memcpy(n, suffix, ls + 1);
        return n;
    }

    size_t lo = strlen(orig);
    size_t ls = strlen(suffix);
    char *n = realloc(orig, lo + ls + 1);
    if (!n)
        return orig; /* keep original on realloc failure */
    memcpy(n + lo, suffix, ls + 1);
    return n;
}

char *talloc_asprintf_append(char *s, const char *fmt, ...) { char tmp[128]; va_list ap; va_start(ap, fmt); vsnprintf(tmp,sizeof(tmp),fmt,ap); va_end(ap); return dup_cat(s,tmp); }
char *talloc_strdup_append_buffer(char *s, const char *suffix) { return dup_cat(s,suffix?suffix:""); }
char *talloc_strndup_append_buffer(char *s, const char *a, size_t n) { char tmp[128]; if(!a) return s; size_t l = n<sizeof(tmp)-1?n:sizeof(tmp)-1; memcpy(tmp,a,l); tmp[l]='\0'; return dup_cat(s,tmp); }

void talloc_report_full(const void *ctx, void *f) { (void)ctx; FILE *fp = f; if (fp) fprintf(fp,"[pseudotalloc] report_full stub\n"); }
const char *talloc_get_name(const void *ptr) { (void)ptr; return "pseudotalloc"; }
size_t talloc_total_blocks(const void *ptr) { (void)ptr; return 0; }
int talloc_reference_count(const void *ptr) { (void)ptr; return 1; }
void talloc_report_depth_cb(const void *root, int depth, int max_depth, void (*cb)(const void*,int,int,int,void*), void *priv) { (void)root;(void)depth;(void)max_depth;(void)cb;(void)priv; }
#endif /* pseudotalloc conditions */
